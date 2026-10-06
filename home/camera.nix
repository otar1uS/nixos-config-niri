# ═══════════════════════════════════════════════════════════════════════════
#  home/camera.nix  —  the webcam: photos, videos, and its picture settings
# ═══════════════════════════════════════════════════════════════════════════
#
#  Two apps (both in the app launcher, Super+Space):
#    "Camera"           GNOME Snapshot, written in Rust. Take photos and
#                       record videos. Saves to ~/Pictures/Camera and
#                       ~/Videos/Camera.
#    "Camera Settings"  cameractrls. Brightness, contrast, exposure, white
#                       balance, sharpness, colour looks ("film", "vivid"...).
#                       Changes show live, even while "Camera" is open.
#
#  Your settings survive reboots, in two steps:
#   1. When you CLOSE "Camera Settings", what you set is saved as preset 1
#      (in ~/.config/hu.irl.cameractrls/). You don't need to press anything.
#   2. A small background service, cameractrlsd, puts preset 1 back every
#      time the camera appears: at login, and if it reconnects.
#  Back to factory settings: delete the folder ~/.config/hu.irl.cameractrls
#  and restart the laptop (the camera starts with its defaults again).
#
#  The ThinkPad privacy shutter (the slider above the screen) blocks the
#  picture completely; open it if the camera shows black.

{ pkgs, ... }:

let
  cameractrls = pkgs.cameractrls-gtk4; # the GTK4 version (matches your other apps)

  # "Camera Settings" = open cameractrls, and when you close it, save what you
  # set as preset 1 for every camera. writeShellApplication also checks the
  # script for mistakes while building.
  cameraSettings = pkgs.writeShellApplication {
    name = "camera-settings";
    runtimeInputs = [ cameractrls ];
    text = ''
      cameractrlsgtk4 "$@" || true

      # Every camera has a stable name in /dev/v4l/by-id (index0 = the
      # picture itself; the other indexes are extra data channels).
      for camera in /dev/v4l/by-id/*-video-index0; do
        [ -e "$camera" ] || continue
        cameractrls -d "$camera" -c preset=save_1 || true
      done
    '';
  };
in
{
  home.packages = [
    pkgs.snapshot # "Camera": photos and videos
    cameractrls # gives cameractrlsgtk4, cameractrls (command line), cameraview
    cameraSettings # the `camera-settings` command behind the launcher entry
    pkgs.v4l-utils # `v4l2-ctl --list-ctrls`: inspect the camera from a terminal
  ];

  # Replace cameractrls' own launcher entry with ours (same file name, so it
  # takes its place): it opens the same app, but saves when you close it.
  xdg.desktopEntries."hu.irl.cameractrls" = {
    name = "Camera Settings";
    comment = "Brightness, exposure, colours... (saved when you close it)";
    exec = "camera-settings";
    icon = "hu.irl.cameractrls";
    categories = [ "Settings" "AudioVideo" "Video" ];
    settings.Keywords = "camera;webcam;brightness;exposure;cameractrls;";
  };

  # cameractrlsd: puts preset 1 back whenever a camera appears. Defined here
  # (not with the app's own "install daemon" switch): that switch writes a
  # service pointing to a program path that breaks after NixOS updates.
  systemd.user.services.cameractrlsd = {
    Unit = {
      Description = "Restore camera settings (cameractrls preset 1)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${cameractrls}/bin/cameractrlsd";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
