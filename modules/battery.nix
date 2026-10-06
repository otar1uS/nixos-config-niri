# ═══════════════════════════════════════════════════════════════════════════
#  modules/battery.nix  —  battery charging modes (Desk / Daily / Travel)
# ═══════════════════════════════════════════════════════════════════════════
#
#  Your ThinkPad can stop charging early to make the battery live longer.
#  It stores two numbers inside the laptop itself (they survive reboots):
#    start = only begin charging when the battery is BELOW this %
#    stop  = stop charging when the battery reaches this %
#
#  The modes are defined ONCE, in the `modes` list below. Everything else
#  (the admin jobs, the password-free rule, the command, and the buttons in
#  the bar's battery panel) is generated from that list. To add or change a
#  mode, edit the list and rebuild.
#
#  Changing these numbers needs admin (root) rights, so this file makes:
#    1. one tiny admin job (systemd service) per mode, that writes the numbers
#    2. a rule that lets YOU run just those jobs without a password
#    3. the command `battery-charge-mode`, used by the bar and by you
#
#  In a terminal:
#    battery-charge-mode            show the current mode
#    battery-charge-mode travel     switch to a mode (desk / daily / travel)
#    battery-charge-mode json       everything as JSON (the bar reads this)

{ config, lib, pkgs, ... }:

let
  # ── The modes. Edit here, then rebuild. ─────────────────────────────────
  # id    = short name used in commands (lowercase, no spaces)
  # name  = what the bar shows
  # glyph = icon name from https://tabler.io/icons
  # hint  = one line of explanation shown in the battery panel
  modes = [
    {
      id = "desk";
      name = "Desk";
      start = 35;
      stop = 40;
      glyph = "plug-connected";
      hint = "Plugged in all day. Kindest to the battery.";
    }
    {
      id = "daily";
      name = "Daily";
      start = 75;
      stop = 80;
      glyph = "battery-3";
      hint = "A good everyday balance of range and battery life.";
    }
    {
      id = "travel";
      name = "Travel";
      start = 95;
      stop = 100;
      glyph = "plane";
      hint = "Charge to full before you go out. Switch back after.";
    }
  ];

  # Where Linux shows the battery's settings as small text files.
  battery = "/sys/class/power_supply/BAT0";

  # The mode list saved as a JSON file, for the command below.
  modesFile = pkgs.writeText "battery-modes.json" (builtins.toJSON modes);

  # ── 1. One admin job per mode ─────────────────────────────────────────
  # The laptop refuses a start that is higher than the current stop.
  # So we first open the stop to 100 (always allowed), then set start,
  # then set the real stop. This order works from any previous setting.
  makeJob = mode: {
    description = "Battery charging: ${mode.name} mode (${toString mode.start}-${toString mode.stop}%)";
    serviceConfig.Type = "oneshot"; # runs once and finishes, like a command
    script = ''
      echo 100 > ${battery}/charge_control_end_threshold
      echo ${toString mode.start} > ${battery}/charge_control_start_threshold
      echo ${toString mode.stop} > ${battery}/charge_control_end_threshold
    '';
  };

  # The job names, e.g. [ "battery-charge-desk.service" ... ].
  jobNames = map (mode: "battery-charge-${mode.id}.service") modes;

  # ── 3. The command ────────────────────────────────────────────────────
  # writeShellApplication makes a shell script AND checks it for mistakes
  # (with shellcheck) while building, so a typo stops the rebuild.
  batteryChargeMode = pkgs.writeShellApplication {
    name = "battery-charge-mode";
    # The programs the script uses: systemctl (to start a job) and jq (to
    # read the mode list).
    runtimeInputs = [ config.systemd.package pkgs.jq ];
    text = ''
      modes=$(cat ${modesFile})
      start=$(cat ${battery}/charge_control_start_threshold)
      stop=$(cat ${battery}/charge_control_end_threshold)

      # Which mode has exactly these numbers? ("custom" if none does.)
      current=$(jq -r --argjson a "$start" --argjson b "$stop" \
        'map(select(.start == $a and .stop == $b)) | .[0].id // "custom"' <<<"$modes")

      case "''${1:-status}" in
        status)
          echo "$current mode: charging starts below $start % and stops at $stop %"
          ;;
        json)
          jq -c --arg current "$current" --argjson start "$start" --argjson stop "$stop" \
            '{current: $current, start: $start, stop: $stop, modes: .}' <<<"$modes"
          ;;
        *)
          # Is the word a known mode id? Then start that mode's admin job.
          if jq -e --arg id "$1" 'any(.id == $id)' <<<"$modes" >/dev/null; then
            systemctl start "battery-charge-$1.service"
          else
            echo "usage: battery-charge-mode [status | json | $(jq -r 'map(.id) | join(" | ")' <<<"$modes")]" >&2
            exit 1
          fi
          ;;
      esac
    '';
  };
in
{
  # 1. The admin jobs: battery-charge-desk.service, battery-charge-daily...
  systemd.services = lib.listToAttrs (
    map (mode: lib.nameValuePair "battery-charge-${mode.id}" (makeJob mode)) modes
  );

  # 2. The password-free rule. polkit is the part of Linux that decides
  # who may do admin things. This says: a user in the "wheel" group (you),
  # sitting at this laptop, may START these jobs. Nothing else.
  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      var batteryJobs = ${builtins.toJSON jobNames};
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("verb") == "start" &&
          batteryJobs.indexOf(action.lookup("unit")) >= 0 &&
          subject.isInGroup("wheel") && subject.local && subject.active) {
        return polkit.Result.YES;
      }
    });
  '';

  # 3. Install the command for everyone.
  environment.systemPackages = [ batteryChargeMode ];
}
