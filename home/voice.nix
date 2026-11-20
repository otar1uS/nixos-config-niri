# ═══════════════════════════════════════════════════════════════════════════
#  home/voice.nix  —  voice typing: press F9 (or Super+Alt+D), talk, press again
# ═══════════════════════════════════════════════════════════════════════════
#
#  Voxtype turns speech into text ON THE LAPTOP (nothing goes online) and
#  types it into the focused window.
#
#  Model: NVIDIA Parakeet TDT 0.6B v2, one of the most accurate open English
#  models; adds punctuation and capitals itself. Full precision (2.5 GB),
#  loaded only while you talk. (Fedora used Whisper base.en: smaller, less
#  accurate.) Pinned to an exact revision + hash, so it can't change.
#
#  Logs: journalctl --user -u voxtype

{ pkgs, ... }:

let
  # Parakeet needs the ONNX build of Voxtype.
  voxtype = pkgs.voxtype.override { onnxSupport = true; };

  rev = "0bbb45a3365852604aef28b538a8f066f4ccaa85";
  modelFile = name: sha256: {
    inherit name;
    path = pkgs.fetchurl {
      url = "https://huggingface.co/istupakov/parakeet-tdt-0.6b-v2-onnx/resolve/${rev}/${name}";
      inherit sha256;
    };
  };
  parakeetModel = pkgs.linkFarm "parakeet-tdt-0.6b-v2" [
    (modelFile "encoder-model.onnx" "3987bcd28175d829d12888a996a84e8f62a0e374d9ffd640662c1515adc679d3")
    (modelFile "encoder-model.onnx.data" "4dab7362d4874d85965045b1e41b2d61dd2cc0fb25671a7f6b3dc47bf120cc41")
    (modelFile "decoder_joint-model.onnx" "cbb52a07bd70ab5b67f8439d4b3cd8704b18467b4430bcacb5adabe154b8d191")
    (modelFile "vocab.txt" "0za9gnbm6zxxggsj48xj7r255jaqmifcfwjkdkzkl4a2vmq2n67c")
    (modelFile "config.json" "0rn4i8ad5h1vga6yq04qpy6qmc30rpvd9bqhqbrcm64pdg3h6sb6")
  ];
in
{
  services.voxtype = {
    enable = true;
    package = voxtype;
    settings = {
      engine = "parakeet";
      parakeet = {
        model = "${parakeetModel}";
        on_demand_loading = true; # load when you start talking, free memory after
      };

      # Umbriel's F9 bind runs `voxtype record toggle` (home/umbriel/binds.nix).
      hotkey = {
        enabled = false;
        mode = "toggle";
      };

      audio.feedback = {
        enabled = true;
        theme = "subtle";
        volume = 0.5;
      };

      output = {
        mode = "type"; # type where the cursor is (wtype)
        fallback_to_clipboard = true;
        notification = {
          on_recording_start = true;
          on_recording_stop = false;
          on_transcription = false;
        };
      };
    };
  };
}
