# ═══════════════════════════════════════════════════════════════════════════
#  modules/thinkpad.nix  —  fan modes, the lid-logo LED, and temperatures
# ═══════════════════════════════════════════════════════════════════════════
#
#  FAN MODES (safe ones only: they never make the fan SLOWER than the
#  laptop would choose itself, so nothing can overheat):
#    auto     the laptop decides (quiet, the factory behaviour)
#    charger  full speed while the charger is plugged in, auto on battery
#             (cooler laptop at the desk; quiet when you're out)
#    max      full speed all the time
#
#  LID LED (the red dot on the "i" of the ThinkPad logo on the lid):
#    off / on / charging (lit only while the battery is charging)
#
#  Your choices are remembered in /var/lib/thinkpad/ and put back after a
#  reboot or after waking from sleep. Plugging the charger in or out
#  switches the fan by itself, even if the bar isn't running.
#
#  Like modules/battery.nix: small admin jobs do the writing, a rule lets
#  you start just those jobs without a password, and a command
#  (`thinkpad`) is what you and the bar's ThinkPad panel use:
#    thinkpad              show everything as JSON (temperatures, fan, LED)
#    thinkpad fan charger  pick a fan mode   (auto / charger / max)
#    thinkpad led charging pick an LED mode  (off / on / charging)

{ config, lib, pkgs, ... }:

let
  fanModes = [ "auto" "charger" "max" ];
  ledModes = [ "off" "on" "charging" ];

  fanFile = "/proc/acpi/ibm/fan"; # the fan's control file (from the thinkpad_acpi driver)
  ledDir = "/sys/class/leds/tpacpi::lid_logo_dot";
  stateDir = "/var/lib/thinkpad"; # where the chosen modes are remembered

  # ── The part that runs as admin (root) ────────────────────────────────
  # Reads the remembered modes and sets the fan and LED to match.
  # Level 7 = the fan's fastest *regulated* speed. (We never use
  # "disengaged"/"full-speed": the kernel docs warn it can exceed the fan's
  # limits. And never low levels: those could let it overheat.)
  apply = pkgs.writeShellScript "thinkpad-apply" ''
    fan=$(cat ${stateDir}/fan 2>/dev/null || echo auto)
    led=$(cat ${stateDir}/led 2>/dev/null || echo "")
    plugged=$(cat /sys/class/power_supply/AC/online 2>/dev/null || echo 0)

    case "$fan" in
      max) level=7 ;;
      charger) if [ "$plugged" = 1 ]; then level=7; else level=auto; fi ;;
      *) level=auto ;;
    esac
    echo "level $level" > ${fanFile}

    # The LED is only touched once you've picked a mode.
    case "$led" in
      off) echo none > ${ledDir}/trigger; echo 0 > ${ledDir}/brightness ;;
      on) echo none > ${ledDir}/trigger; echo 255 > ${ledDir}/brightness ;;
      charging) echo BAT0-charging > ${ledDir}/trigger ;;
    esac
  '';

  # One admin job per mode: remember the choice, then apply it.
  makeJob = kind: mode: {
    description = "ThinkPad: set ${kind} mode to ${mode}";
    serviceConfig = {
      Type = "oneshot";
      StateDirectory = "thinkpad"; # systemd creates /var/lib/thinkpad for us
    };
    script = ''
      echo ${mode} > ${stateDir}/${kind}
      ${apply}
    '';
  };

  jobs =
    map (m: { name = "thinkpad-fan-${m}"; value = makeJob "fan" m; }) fanModes
    ++ map (m: { name = "thinkpad-led-${m}"; value = makeJob "led" m; }) ledModes;

  # ── The command (runs as you, no admin needed for reading) ────────────
  thinkpadCmd = pkgs.writeShellApplication {
    name = "thinkpad";
    runtimeInputs = [ config.systemd.package pkgs.jq ];
    text = ''
      # Temperature of the first sensor called NAME, in °C ("null" if none).
      # Linux numbers the sensors (hwmon0, hwmon1...) differently on each
      # boot, so we look them up by name instead.
      temp() {
        for h in /sys/class/hwmon/hwmon*; do
          if [ "$(cat "$h/name" 2>/dev/null)" = "$1" ]; then
            v=$(cat "$h/temp1_input" 2>/dev/null) && echo $((v / 1000)) && return
          fi
        done
        echo null
      }
      fanRpm() {
        for h in /sys/class/hwmon/hwmon*; do
          if [ "$(cat "$h/name" 2>/dev/null)" = thinkpad ]; then
            cat "$h/fan1_input" 2>/dev/null && return
          fi
        done
        echo null
      }

      case "''${1:-json}" in
        json)
          level=$(sed -n 's/^level:[[:space:]]*//p' ${fanFile})
          # Can the fan be controlled? Needs the driver option from below,
          # which only takes effect after a reboot.
          control=false
          grep -q '^commands:' ${fanFile} && control=true
          jq -nc \
            --argjson cpu "$(temp k10temp)" --argjson gpu "$(temp amdgpu)" \
            --argjson ssd "$(temp nvme)" --argjson wifi "$(temp mt7921_phy0)" \
            --argjson rpm "$(fanRpm)" --arg level "$level" --argjson control "$control" \
            --arg fan "$(cat ${stateDir}/fan 2>/dev/null || echo auto)" \
            --arg led "$(cat ${stateDir}/led 2>/dev/null || echo "")" \
            --argjson plugged "$(cat /sys/class/power_supply/AC/online 2>/dev/null || echo 0)" \
            '{temps: {cpu: $cpu, gpu: $gpu, ssd: $ssd, wifi: $wifi},
              fan: {rpm: $rpm, level: $level, mode: $fan, control: $control},
              led: $led, plugged: ($plugged == 1)}'
          ;;
        fan | led)
          mode="''${2:-}"
          if [ "$1" = fan ]; then allowed="${toString fanModes}"; else allowed="${toString ledModes}"; fi
          if [[ " $allowed " == *" $mode "* ]]; then
            systemctl start "thinkpad-$1-$mode.service"
          else
            echo "usage: thinkpad $1 [''${allowed// / | }]" >&2
            exit 1
          fi
          ;;
        *)
          echo "usage: thinkpad [json | fan <mode> | led <mode>]" >&2
          exit 1
          ;;
      esac
    '';
  };
in
{
  # Let the thinkpad_acpi driver accept fan commands at all (it ignores them
  # by default). Driver options are read when the driver loads at startup,
  # so this needs ONE reboot after the first rebuild.
  boot.extraModprobeConfig = ''
    options thinkpad_acpi fan_control=1
  '';

  systemd.services = lib.listToAttrs jobs // {
    # Puts the remembered modes back at startup and after waking from sleep
    # (the laptop forgets fan and LED settings when it sleeps).
    thinkpad-apply = {
      description = "ThinkPad: restore fan and LED modes";
      wantedBy = [ "multi-user.target" "post-resume.target" ];
      after = [ "post-resume.target" ];
      serviceConfig = {
        Type = "oneshot";
        StateDirectory = "thinkpad";
        ExecStart = "${apply}";
      };
    };
  };

  # Charger plugged in or out -> re-check the fan ("charger" mode). udev is
  # the part of Linux that reacts to hardware events like this one.
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", KERNEL=="AC", ACTION=="change", RUN+="${config.systemd.package}/bin/systemctl start --no-block thinkpad-apply.service"
  '';

  # The password-free rule, like in battery.nix: you (group "wheel"), at
  # this laptop, may START these mode jobs. Nothing else.
  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      var thinkpadJobs = ${builtins.toJSON (map (j: "${j.name}.service") jobs)};
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("verb") == "start" &&
          thinkpadJobs.indexOf(action.lookup("unit")) >= 0 &&
          subject.isInGroup("wheel") && subject.local && subject.active) {
        return polkit.Result.YES;
      }
    });
  '';

  environment.systemPackages = [ thinkpadCmd ];
}
