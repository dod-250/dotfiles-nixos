# =================
# hyprland-conf.nix
# =================

{ config, pkgs, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      
      # === Monitors Configuration ===
      monitor = [
        ",preferred,auto,1"
        # "DP-1,2560x1440@144,0x0,1"    # Exemple monitor externe
        # "eDP-1,1920x1080@60,2560x0,1" # Exemple laptop
      ];

      # === Autostart Applications ===
      exec-once = [
        "waybar"
        "swaynotificationcenter"
        "hyprpaper"
        "hypridle"
        "nm-applet"
        "blueman-applet"
        "cliphist daemon"
      ];

      # === Environment Variables ===
      env = [
        "XCURSOR_SIZE,24"
        "QT_QPA_PLATFORMTHEME,qt6ct"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "MOZ_ENABLE_WAYLAND,1"
        "GDK_BACKEND,wayland,x11"
        "SDL_VIDEODRIVER,wayland"
        "CLUTTER_BACKEND,wayland"
      ];

      # === Input Configuration ===
      input = {
        kb_layout = "us";
        kb_variant = "";
        kb_model = "";
        kb_options = "";
        kb_rules = "";

        follow_mouse = 1;
        mouse_refocus = false;
        
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
          drag_lock = false;
          disable_while_typing = true;
          clickfinger_behavior = true;
          scroll_factor = 0.3;
        };

        sensitivity = 0.0; # -1.0 à 1.0
        accel_profile = "flat";
      };

      # === General Settings ===
      general = {
        gaps_in = 8;
        gaps_out = 15;
        border_size = 3;
        
        "col.active_border" = "rgb(f5a97f)";
        "col.inactive_border" = "rgb(a6da95)";
        
        layout = "dwindle";
        allow_tearing = false;
        resize_on_border = true;
        extend_border_grab_area = 20;
        hover_icon_on_border = true;
      };

      # === Decorations ===
      decoration = {
        rounding = 1;

        active_opacity = 1;
        inactive_opacity = 0.97;
        
        dim_inactive = false;
        dim_strength = 0.1;
        dim_special = 0.5;
        dim_around = 0.4;
      };
        
      # === Animations ===
      animations = {
        enabled = true;

        bezier = [
          "wind, 0.05, 0.9, 0.1, 1.05"
          "winIn, 0.1, 1.1, 0.1, 1.1"
          "winOut, 0.3, -0.3, 0, 1"
          "liner, 1, 1, 1, 1"
          "linear, 0.0, 0.0, 1.0, 1.0"
        ];

        animation = [
          "windows, 1, 6, wind, slide"
          "windowsIn, 1, 6, winIn, slide"
          "windowsOut, 1, 5, winOut, slide"
          "windowsMove, 1, 5, wind, slide"
          "border, 1, 10, linear"
          "borderangle, 1, 8, linear"
          "fade, 1, 10, default"
          "workspaces, 1, 5, wind"
          "specialWorkspace, 1, 8, wind, slidevert"
        ];
      };

      # === Layouts ===
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        smart_split = false;
        smart_resizing = true;
        permanent_direction_override = false;
        special_scale_factor = 0.8;
        split_width_multiplier = 1.0;
        use_active_for_splits = true;
        default_split_ratio = 1.0;
      };

      master = {
        new_on_top = false;
        orientation = "left";
        inherit_fullscreen = true;
        smart_resizing = true;
        drop_at_cursor = true;
      };

      # === Gestures ===
      gestures = {
        workspace_swipe_distance = 300;
        workspace_swipe_invert = true;
        workspace_swipe_min_speed_to_force = 30;
        workspace_swipe_cancel_ratio = 0.5;
        workspace_swipe_create_new = true;
        workspace_swipe_direction_lock = true;
        workspace_swipe_direction_lock_threshold = 10;
        workspace_swipe_forever = false;
      };

      # === Group Configuration ===
      group = {
        insert_after_current = true;
        focus_removed_window = true;
        
        "col.border_active" = "rgba(66cc66ee) rgba(66cc66ee) 45deg";
        "col.border_inactive" = "rgba(595959aa)";
        "col.border_locked_active" = "rgba(c3c3c3ee) rgba(c3c3c3ee) 45deg";
        "col.border_locked_inactive" = "rgba(444444aa)";
        
        groupbar = {
          enabled = true;
          font_family = "0xProto Nerd Font";
          font_size = 8;
          gradients = true;
          height = 14;
          priority = 3;
          render_titles = true;
          scrolling = true;
        };
      };

      # === Miscellaneous ===
      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = false;
        always_follow_on_dnd = true;
        layers_hog_keyboard_focus = true;
        animate_manual_resizes = false;
        animate_mouse_windowdragging = false;
        disable_autoreload = false;
        enable_swallow = true;
        swallow_regex = "^(kitty|alacritty|Alacritty)$";
        focus_on_activate = false;
        mouse_move_focuses_monitor = true;
        allow_session_lock_restore = false;
        close_special_on_empty = true;
        new_window_takes_over_fullscreen = 0;
      };

      # === Binds Configuration ===
      binds = {
        pass_mouse_when_bound = false;
        scroll_event_delay = 300;
        workspace_back_and_forth = false;
        allow_workspace_cycles = false;
        workspace_center_on = 0;
        focus_preferred_method = 0;
        ignore_group_lock = false;
        movefocus_cycles_fullscreen = true;
      };

      # === XWayland ===
      xwayland = {
        use_nearest_neighbor = true;
        force_zero_scaling = false;
      };

      # === Window Rules ===
      windowrule = [
      ];

      windowrulev2 = [
        "noshadow,class:.*"

        "suppressevent maximize, class:.*"
        "float,class:^(kitty)$,title:^(kitty)$"
        "center,class:^(kitty)$,title:^(kitty)$"
        "size 800 600,class:^(kitty)$,title:^(kitty)$"

        "suppressevent maximize, class:.*"
        "float,class:^(waypaper)$,title:^(waypaper)$"
        "center,class:^(waypaper)$,title:^(waypaper)$"
        "size 800 600,class:^(waypaper)$,title:^(waypaper)$"
        
        "idleinhibit focus,class:^(mpv)$"
        "idleinhibit focus,class:^(firefox)$"
        "idleinhibit fullscreen,class:^(firefox)$"
        
        "pin,class:^(showmethekey-gtk)$"
        "float,class:^(showmethekey-gtk)$"
        "noborder,class:^(showmethekey-gtk)$"
        "nofocus,class:^(showmethekey-gtk)$"
        "noblur,class:^(showmethekey-gtk)$"
        "noshadow,class:^(showmethekey-gtk)$"
      ];

      layerrule = [
        # "blur,rofi"
        # "ignorezero,rofi"
        # "blur,notifications"
        # "ignorezero,notifications"
        # "blur,waybar"
        # "ignorezero,waybar"
      ];

      # === Key Bindings  ===
      "$mainMod" = "SUPER";
      "$terminal" = "kitty";
      "$fileManager" = "thunar";
      "$menu" = "rofi -show drun";
      "$browser" = "firefox";

      bind = [
        # Basic window management
        "$mainMod, T, exec, $terminal"
        "$mainMod, B, exec, $browser"
        "$mainMod, Y, exec, kitty -e btop"
        "$mainMod, U, exec, kitty -e fastfetch"
        "$mainMod, I, exec, kitty -e cmatrix"
        "$mainMod, O, exec, kitty -e nvim"
        "$mainMod, W, exec, waypaper"
        "$mainMod, Q, killactive"
        "$mainMod, M, exit"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, V, togglefloating"
        "$mainMod, R, exec, $menu"
        "$mainMod, P, pseudo" # dwindle
        "$mainMod, J, togglesplit" # dwindle
        "$mainMod, F, fullscreen"
        "$mainMod, ESCAPE, exec, wlogout"
        ", PRINT, exec, hyprshot -m output"
        "$mainMod, PRINT, exec, hyprshot -m window"
        "$SUPER_SHIFT, PRINT, exec, hyprshot -m region"
         "$mainMod, C, exec, hyprpicker"
         "$mainMod, F, togglefloating," #Float Mode

        # Focus movement
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        # Workspace switching
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        # Move windows to workspace
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        # Special workspace (scratchpad)
        "$mainMod, S, togglespecialworkspace, magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"

        # System controls (ajuste selon tes besoins)
        "$mainMod, L, exec, hyprlock"
      ];

      # === Mouse Bindings ===
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      # === Volume and Media Controls (bindel for repeat) ===
      bindel = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ", XF86MonBrightnessUp, exec, brightnessctl s 10%+"
        ", XF86MonBrightnessDown, exec, brightnessctl s 10%-"
      ];

      # === Media Player Controls (bindl for single press) ===
      bindl = [
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPause, exec, playerctl play-pause"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"
        "$mainMod, PRINT, exec, hyprshot -m window"
        
      ];
    };
  };
}
