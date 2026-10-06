# ═══════════════════════════════════════════════════════════════════════════
#  home/voice.nix  —  voice typing: press F9 (or Super+D), talk, press again
# ═══════════════════════════════════════════════════════════════════════════
#
#  Voxtype (written in Rust) listens while you talk, turns speech into text
#  ON YOUR LAPTOP (nothing is sent to the internet), and types the text
#  into whatever window you're in, like a very fast keyboard.
#
#  The speech model is NVIDIA's Parakeet TDT 0.6B v2: one of the most
#  accurate open models for English, and it adds punctuation and capital
#  letters by itself. It's the full-precision version (2.5 GB) for the best
#  accuracy. It's loaded only while you talk, so it doesn't sit in memory.
#
#  How to use:
#    F9 (fn+F9 on the Apple keyboard) or Super+D  ->  a notification shows
#    it's listening; talk; press the same key again  ->  the text is typed.
#  Logs, if something doesn't work:  journalctl --user -u voxtype

{ pkgs, pkgs-unstable, ... }:

let
  # The "-onnx" build includes Parakeet (the plain build only has Whisper).
  # From unstable: stable NixOS doesn't have Voxtype at all.
  voxtype = pkgs-unstable.voxtype-onnx;

  # ── The speech model, downloaded once by Nix and pinned ───────────────
  # Each file is pinned to an exact version (`rev`) and checked against
  # its fingerprint (`sha256`), so it can never change or be tampered with.
  rev = "0bbb45a3365852604aef28b538a8f066f4ccaa85";
  modelFile = name: sha256: {
    inherit name;
    path = pkgs.fetchurl {
      url = "https://huggingface.co/istupakov/parakeet-tdt-0.6b-v2-onnx/resolve/${rev}/${name}";
      inherit sha256;
    };
  };
  # linkFarm = a folder in the Nix store that just links to these files.
  parakeetModel = pkgs.linkFarm "parakeet-tdt-0.6b-v2" [
    (modelFile "encoder-model.onnx" "3987bcd28175d829d12888a996a84e8f62a0e374d9ffd640662c1515adc679d3")
    (modelFile "encoder-model.onnx.data" "4dab7362d4874d85965045b1e41b2d61dd2cc0fb25671a7f6b3dc47bf120cc41")
    (modelFile "decoder_joint-model.onnx" "cbb52a07bd70ab5b67f8439d4b3cd8704b18467b4430bcacb5adabe154b8d191")
    (modelFile "vocab.txt" "0za9gnbm6zxxggsj48xj7r255jaqmifcfwjkdkzkl4a2vmq2n67c")
    (modelFile "config.json" "0rn4i8ad5h1vga6yq04qpy6qmc30rpvd9bqhqbrcm64pdg3h6sb6")
  ];

  # ── Voxtype's settings (become ~/.config/voxtype/config.toml) ─────────
  settings = {
    engine = "parakeet";

    parakeet = {
      model = "${parakeetModel}"; # the folder above
      on_demand_loading = true; # load when you start talking, free memory after
    };

    hotkey = {
      enabled = false; # niri's F9 / Super+D runs `voxtype record toggle` instead
      mode = "toggle"; # press once to start, press again to stop
    };

    # A soft click when listening starts and stops.
    audio.feedback = {
      enabled = true;
      theme = "subtle";
      volume = 0.5;
    };

    output = {
      mode = "type"; # type the text where your cursor is
      notification = {
        on_recording_start = true; # "listening" note that stays until you stop
        on_recording_stop = false;
        on_transcription = false; # the text is typed anyway
      };
    };
  };
in
{
  home.packages = [ voxtype ]; # the `voxtype` command (F9 calls it)

  xdg.configFile."voxtype/config.toml".source =
    (pkgs.formats.toml { }).generate "voxtype-config.toml" settings;

  # Voxtype runs in the background while you're logged in to niri, waiting
  # for F9. systemd starts it with the desktop and restarts it if it crashes.
  systemd.user.services.voxtype = {
    Unit = {
      Description = "Voxtype voice typing (F9)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${voxtype}/bin/voxtype daemon";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
