{ config, pkgs, lib, ... }:

{
  # SwayNC configuration
  services.swaync = {
    enable = true;

    style = lib.mkForce ''
      * {
        font-family: "0xProto Nerd Font";
        font-size: 10pt;
      }

      @define-color base00 #24273a;
      @define-color base01 #1e2030;
      @define-color base02 #363a4f;
      @define-color base03 #494d64;
      @define-color base04 #5b6078;
      @define-color base05 #cad3f5;
      @define-color base06 #f4dbd6;
      @define-color base07 #b7bdf8;
      @define-color base08 #f5a97f;
      @define-color base09 #f5a97f;
      @define-color base0A #eed49f;
      @define-color base0B #a6da95;
      @define-color base0C #8bd5ca;
      @define-color base0D #f5a97f;
      @define-color base0E #c6a0f6;
      @define-color base0F #f0c6c6;

      .notification {
        border: 2px solid @base08;
      }

      .notification.low progress {
        background: @base03;
      }

      .notification.normal progress {
        background: @base0F;
      }

      .notification.critical progress {
        background: @base08;
      }

      .summary {
        color: @base05;
      }

      .body {
        color: @base06;
      }

      .time {
        color: @base06;
      }

      .notification-action {
        color: @base05;
        background: @base01;
        border: none;
      }

      .notification-action:hover {
        background: @base01;
        color: @base05;
      }

      .notification-action:active {
        background: @base0F;
        color: @base05;
      }

      .close-button {
        color: @base02;
        background: @base08;
        border: none;
      }

      .close-button:hover {
        background: lighter(@base08);
        color: lighter(@base02);
      }

      .close-button:active {
        background: @base08;
        color: @base00;
      }

      .notification-content {
        background: @base00;
        border: none;
      }

      .notification-background {
        border: none;
      }

      .floating-notifications.background .notification-row .notification-background {
        background: solid;
        color: @base05;
      }

      .notification-group .notification-group-buttons,
      .notification-group .notification-group-headers {
        color: @base05;
      }

      .notification-group .notification-group-headers .notification-group-icon {
        color: @base05;
      }

      .notification-group .notification-group-headers .notification-group-header {
        color: @base05;
      }

      .notification-group.collapsed .notification-row .notification {
        background: @base01;
      }

      .notification-group.collapsed:hover .notification-row:not(:only-child) .notification {
        background: @base01;
      }

      .control-center {
        background: @base00;
        border: 2px solid @base0D;
        color: @base05;
      }

      .control-center .notification-row .notification-background {
        background: @base00;
        color: @base00;
        border: 0px solid @base00;
      }

      .control-center .notification-row .notification-background:hover {
        background: @base00;
        color: @base00;
        border: 2px solid @base0B;
      }

      .control-center .notification-row .notification-background:active {
        background: @base00;
        color: @base00;
        border: 2px solid @base0B;
      }

      .widget-title {
        color: @base05;
        margin: 0.5rem;
        border: none;
      }

      .widget-title > button {
        background: @base01;
        border: 1px solid @base0D;
        color: @base05;
      }

      .widget-title > button:hover {
        background: @base01;
      }

      .widget-dnd {
        color: @base05;
        border: none;
      }

      .widget-dnd > switch {
        background: @base01;
        border: 1px solid @base0D;
      }

      .widget-dnd > switch:hover {
        background: @base01;
      }

      .widget-dnd > switch:checked {
        background: @base0F;
      }

      .widget-dnd > switch slider {
        background: @base06;
      }

      .widget-mpris {
        color: @base05;
        border: none;
      }

      .widget-mpris .widget-mpris-player {
        background: @base01;
        border: 2px solid @base0D;
      }

      .widget-mpris .widget-mpris-player button:hover {
        background: @base01;
      }

      .widget-mpris .widget-mpris-player > box > button {
        border: 1px solid @base0D;
      }

      .widget-mpris .widget-mpris-player > box > button:hover {
        background: @base01;
        border: 1px solid @base0D;
      }

      .floating-notifications {
        padding-top: 20px;
        padding-right: 10px;
      }
  
      .notification-row {
        margin-top: 0px;
      }

      progress,
      progressbar,
      trough {
        border: 1px solid @base0D;
      }

      trough {
        background: @base01;
      }
    '';
    
    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";
      layer-shell = true;
      cssPriority = "user";
      control-center-margin-top = 20;
      control-center-margin-bottom = 0;
      control-center-margin-right = 10;
      control-center-margin-left = 0;
      notification-2fa-action = true;
      notification-inline-replies = false;
      notification-icon-size = 24;
      notification-body-image-height = 100;
      notification-body-image-width = 100;
      timeout = 10;
      timeout-low = 5;
      timeout-critical = 0;
      fit-to-screen = false;
      control-center-width = 450;
      control-center-height = 720;
      notification-window-width = 450;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      transition-time = 100;
      hide-on-clear = false;
      hide-on-action = true;
      script-fail-notify = true;

      # Add MPRIS widget configuration
      widgets = [
        "mpris"
        "title"
        "dnd"
        "notifications"
      ];
      
      widget-config = {
        mpris = {
          image-size = 96;
          image-radius = 12;
          blur = true;
        };
      notifications = {
          text = "Notifications";
          clear-all-button = true;
          button-text = " Clear";
        };
      };
    };
  };
}