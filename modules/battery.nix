# ═══════════════════════════════════════════════════════════════════════════
#  modules/battery.nix  —  battery charging modes
# ═══════════════════════════════════════════════════════════════════════════
#
#  The same five modes as your Fedora `battery-mode` script:
#    docked    hold 35-40%      plugged in all day: kindest to the battery
#    drain     run on battery while plugged in, down to 40%, then -> docked
#    pause     don't charge at all; the laptop runs on the charger
#    balanced  70-80%           everyday use, unplugging often
#    full      95-100%          before a trip, then switch back
#
#  The ThinkPad remembers two numbers itself (start/stop charging at %) and
#  a "behaviour" (auto / inhibit-charge / force-discharge). The chosen mode
#  is saved in /var/lib/battery-mode/mode and put back at boot, after sleep,
#  when the charger is plugged in or out, and once a minute (that's what
#  finishes a Drain on time).
#
#  Changing them needs root, so this file makes:
#    1. one tiny root job per mode (battery-mode-docked.service, ...)
#    2. a polkit rule: YOU, at this laptop, may start just those jobs
#    3. the `battery-mode` command, used by you and by the bar's Battery panel
#
#    battery-mode            show mode, limits, behaviour
#    battery-mode drain      switch mode
#    battery-mode json       everything as JSON (the bar reads this)
#
#  To change a mode or add one: edit `modes`, rebuild. The panel's buttons
#  are made from this list.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  # glyph = icon name from https://tabler.io/icons
  # start/stop = null leaves the current limits alone.
  # drainTo/after: force-discharge until the battery is at drainTo %, then
  # switch to the `after` mode by itself.
  modes = [
    {
      id = "docked";
      name = "Docked";
      start = 35;
      stop = 40;
      behaviour = "auto";
      glyph = "device-desktop";
      hint = "Holds 35-40%. Best for battery life when plugged in for long.";
    }
    {
      id = "drain";
      name = "Drain";
      start = 35;
      stop = 40;
      behaviour = "force-discharge";
      drainTo = 40;
      after = "docked";
      glyph = "trending-down";
      hint = "Runs on battery while plugged in, down to 40%, then switches to Docked.";
    }
    {
      id = "pause";
      name = "Pause";
      start = null;
      stop = null;
      behaviour = "inhibit-charge";
      glyph = "player-pause";
      hint = "Stops charging at the current level; the laptop runs on the charger.";
    }
    {
      id = "balanced";
      name = "Balanced";
      start = 70;
      stop = 80;
      behaviour = "auto";
      glyph = "battery-eco";
      hint = "Charges between 70 and 80%. Daily use with unplugging.";
    }
    {
      id = "full";
      name = "Full";
      start = 95;
      stop = 100;
      behaviour = "auto";
      glyph = "battery-4";
      hint = "Charges to 100%. Before a trip, then switch back.";
    }
  ];

  battery = "/sys/class/power_supply/BAT0";
  stateFile = "/var/lib/battery-mode/mode";
  ids = map (m: m.id) modes;
  modesFile = pkgs.writeText "battery-modes.json" (builtins.toJSON modes);

  # One `case` branch of the root script per mode.
  modeCase =
    m:
    let
      limits = lib.optionalString (
        m.start != null
      ) "set_thresholds ${toString m.start} ${toString m.stop}";
      drain = ''
        if [ "$(cat "$BAT/capacity")" -le ${toString m.drainTo} ]; then
          echo ${m.after} > "$STATE"
          apply_mode ${m.after}
        else
          set_behaviour ${m.behaviour}
        fi
      '';
    in
    ''
      ${m.id})
        ${limits}
        ${if m ? drainTo then drain else "set_behaviour ${m.behaviour}"}
        ;;
    '';

  # ── The root part: applies the saved mode ────────────────────────────
  # writeShellApplication also runs shellcheck on it while building.
  apply = pkgs.writeShellApplication {
    name = "battery-mode-apply";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
    ];
    text = ''
      BAT=${battery}
      STATE=${stateFile}

      # The firmware refuses start >= stop, even for a moment. Opening stop
      # to 100 first makes every order of changes valid.
      set_thresholds() {
        if [ "$(cat "$BAT/charge_control_start_threshold")" = "$1" ] &&
          [ "$(cat "$BAT/charge_control_end_threshold")" = "$2" ]; then
          return
        fi
        echo 100 > "$BAT/charge_control_end_threshold"
        echo "$1" > "$BAT/charge_control_start_threshold"
        echo "$2" > "$BAT/charge_control_end_threshold"
      }

      # charge_behaviour reads like "[auto] inhibit-charge force-discharge".
      set_behaviour() {
        grep -q "\[$1\]" "$BAT/charge_behaviour" || echo "$1" > "$BAT/charge_behaviour"
      }

      apply_mode() {
        case "$1" in
          ${lib.concatMapStrings modeCase modes}
          *)
            echo "battery-mode: unknown mode '$1'" >&2
            exit 1
            ;;
        esac
      }

      mode=$(cat "$STATE" 2>/dev/null || true)
      [ -n "$mode" ] || exit 0 # nothing chosen yet: leave the laptop's own settings
      apply_mode "$mode"
    '';
  };

  rootUnit = description: script: {
    inherit description script;
    serviceConfig = {
      Type = "oneshot";
      StateDirectory = "battery-mode"; # systemd creates /var/lib/battery-mode
    };
  };

  modeJobs = lib.listToAttrs (
    map (
      m:
      lib.nameValuePair "battery-mode-${m.id}" (
        rootUnit "Battery charging: ${m.name} mode" ''
          echo ${m.id} > ${stateFile}
          ${lib.getExe apply}
        ''
      )
    ) modes
  );
  jobNames = map (id: "battery-mode-${id}.service") ids;

  # ── The command (runs as you; reading needs no root) ─────────────────
  batteryMode = pkgs.writeShellApplication {
    name = "battery-mode";
    runtimeInputs = [
      config.systemd.package
      pkgs.jq
      pkgs.gnused
      pkgs.coreutils
    ];
    text = ''
      BAT=${battery}
      current=$(cat ${stateFile} 2>/dev/null || echo custom)
      start=$(cat "$BAT/charge_control_start_threshold")
      stop=$(cat "$BAT/charge_control_end_threshold")
      behaviour=$(sed -n 's/.*\[\([a-z-]*\)\].*/\1/p' "$BAT/charge_behaviour")
      capacity=$(cat "$BAT/capacity")
      status=$(cat "$BAT/status")

      case "''${1:-status}" in
        status)
          echo "mode:      $current"
          echo "battery:   $capacity% ($status)"
          echo "limits:    starts below $start%, stops at $stop%"
          echo "behaviour: $behaviour"
          ;;
        json)
          jq -c --arg current "$current" --argjson start "$start" --argjson stop "$stop" \
            --arg behaviour "$behaviour" --argjson capacity "$capacity" \
            '{current: $current, start: $start, stop: $stop, behaviour: $behaviour,
              capacity: $capacity, modes: .}' ${modesFile}
          ;;
        ${lib.concatStringsSep " | " ids})
          systemctl start "battery-mode-$1.service"
          ;;
        *)
          echo "usage: battery-mode [status | json | ${lib.concatStringsSep " | " ids}]" >&2
          exit 1
          ;;
      esac
    '';
  };
in
{
  systemd.services = modeJobs // {
    battery-mode-apply = rootUnit "Battery charging: re-apply the saved mode" (lib.getExe apply) // {
      wantedBy = [
        "multi-user.target"
        "post-resume.target"
      ];
      after = [ "post-resume.target" ];
    };
  };

  # Once a minute: ends a Drain at 40% even if nothing else happens.
  systemd.timers.battery-mode-apply = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "1min";
      AccuracySec = "15s";
    };
  };

  # Charger plugged in or out: re-apply right away.
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ACTION=="change", RUN+="${config.systemd.package}/bin/systemctl start --no-block battery-mode-apply.service"
  '';

  # You (wheel), sitting at this laptop, may START the mode jobs. Nothing else.
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

  environment.systemPackages = [ batteryMode ];
}
