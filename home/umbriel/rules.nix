# Per-window and per-panel rules. (Merged into ~/.config/umbriel/config.toml.)
# Rules apply in order; later ones win. app_id / title are regular
# expressions. Find a window's app_id with: umbriel windows
{
  window_rule = [
    # Blur behind see-through windows (foot is 85% opaque).
    {
      blur = true;
      blur_optimized = true;
    }

    # Noctalia's settings window and Umbriel's share picker float.
    {
      match.app_id = "^dev.noctalia.Noctalia$";
      default_floating = true;
      default_floating_size_px = {
        width = 1020;
        height = 900;
      };
    }
    {
      match.app_id = "^dev.noctalia.UmbrielSharePicker$";
      default_floating = true;
      default_floating_size_px = {
        width = 800;
        height = 600;
      };
    }

    # Small dialogs that should never become a full column.
    {
      match.app_id = "^(org.pulseaudio.pavucontrol|hu.irl.cameractrls|nm-connection-editor|blueman-manager)$";
      default_floating = true;
    }

    # Picture-in-picture video in the corner, above everything.
    {
      match.title = "^(Picture-in-Picture|Picture in picture)$";
      default_floating = true;
      default_maximize = false;
      default_pinned = true;
      default_position = {
        x = 20;
        y = 20;
        anchor = "bottom_right";
      };
    }

    # Brave/Chrome notification toasts: corner, no focus.
    {
      match.title = "^notificationtoasts_.+_desktop";
      default_position = {
        x = 0;
        y = 0;
        anchor = "bottom_right";
      };
      default_focused = false;
      default_pinned = true;
    }

    # Keep Umbriel's shortcuts working while a VM window is focused
    # (Super+Escape still lets the VM grab them when you want).
    {
      match.app_id = "^virt-manager$";
      allow_shortcuts_inhibit = false;
    }
  ];

  # Blur behind Noctalia's bar, panels, notifications and OSDs.
  layer_rule = [
    {
      match.namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd|desktop-widget-[^\"]*)$";
      blur = true;
      blur_ignore_alpha = 0.5;
      blur_popups = true;
    }
    {
      match.namespace = "^noctalia-(notification|dock|panel|attached-panel|osd)$";
      blur_optimized = false;
    }
  ];
}
