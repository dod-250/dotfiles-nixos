# =================
# hyprland-pkgs.nix
# =================

{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # === Hyprland ecosystem ===
    hyprpaper          # Wallpaper daemon
    hyprlock           # Screen locker
    hypridle           # Idle daemon
    hyprpicker         # Color picker

    # === Terminal & Shell ===
    kitty              # Terminal emulator
    fish               # Shell
    starship           # Prompt

    # ===  Files===
    xfce.thunar         # Files manager
    xfce.thunar-volman         # Thunar extension for automatic management of removable drives and media
    xfce.thunar-archive-plugin         # Thunar plugin providing file context menus for archives
    xfce.mousepad           # Text editor
    kdePackages.gwenview            # Photo viewer
    gvfs         # Virtual Filesystem support library
    samba
    kdePackages.ark

    # === Launchers & Menus ===
    rofi       # Application launcher

    # === Status bar ===
    waybar             # Status bar

    # === Notifications ===
    swaynotificationcenter   # Notification center
    libnotify          # Notification library

    # === Screenshot & Screen recording ===
    hyprshot           # Screenshot utility
    obs-studio         # Advanced recording

    # === Clipboard ===
    wl-clipboard       # Wayland clipboard
    cliphist           # Clipboard history

    # === Browsers ===
    firefox            # Web browser

    # === Media ===
    pavucontrol        # Audio control GUI
    cava               # Audio visualizer
    wireplumber        # Modular session / policy manager for PipeWire
    playerctl          # Media player controller
    pulseaudio
    plex-desktop

    # === Screen ===b
    brightnessctl      # Read and control device brightness

    # === Screenshot ===
    grim

    # === System monitoring ===
    btop               # Modern system monitor
    fastfetch          # System info

    # === Network ===
    networkmanagerapplet  # Network manager GUI
    tailscale

    # === Fonts ===
    nerd-fonts._0xproto

    # === Power ===
    powertop

    # === Bluetooth ===
    blueman            # Bluetooth manager

    # === Theme & Appearance ===
    waypaper  # Wallpaper setter

    # === Productivity ===
    onlyoffice-desktopeditors
    joplin-desktop
  ];
}
