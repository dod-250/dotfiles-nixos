{ config, pkgs, spicetify-nix, ... }:
{
  imports = [
    ./modules/sh.nix
    ./modules/starship.nix
    ./modules/spicetify.nix
    ./modules/nixvim.nix
    ./modules/swaync.nix
    ./hyprland/hyprland-pkgs.nix
    ./hyprland/hyprland-conf.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "dod";
  home.homeDirectory = "/home/dod";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    polybarFull
    cmatrix
    _0xproto
    clock-rs
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/dod/etc/profile.d/hm-session-vars.sh
  #

  nixpkgs.config.allowUnfree = true;

  # Stylix

  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";

    polarity = "dark";

    override = {
      base0D = "f5a97f";
      base08 = "f5a97f";
    };

    targets = {
      qt.enable = false;
      swaync.enable = true;
    };
    
    fonts = {
      monospace = {
        package = pkgs._0xproto;
        name = "0xProto Nerd Font";
      };
      sansSerif = {
        package = pkgs._0xproto;
        name = "0xProto Nerd Font";
      };
    };
  };

  # Clock-rs

  programs.clock-rs = {
    enable = true;

    settings = {
      general = {
        color = "green";
        interval = 250;
        blink = true;
        bold = true;
      };

      position = {
        horizontal = "center";
        vertical = "center";
      };

      date = {
        fmt = "%A, %B %d, %Y";
        use_12h = false;
        utc = true;
        hide_seconds = true;
      };
    };
  };

  home.sessionVariables = {
    # EDITOR = "emacs";
  };
  
  programs.fish = {
    enable = true;

    interactiveShellInit = builtins.readFile ./interactive-init.fish;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

}