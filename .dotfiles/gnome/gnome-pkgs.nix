# =================
# gnome-pkgs.nix
# =================

{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
  
    # Settings
    gnome-tweaks
    
    # Extensions
    gnomeExtensions.open-bar
    gnomeExtensions.arcmenu
    gnomeExtensions.kiwi-is-not-apple
    gnomeExtensions.tailscale-status
    gnomeExtensions.proton-vpn-button
    gnomeExtensions.dash2dock-lite
    gnomeExtensions.blur-my-shell
    
  ];
}
