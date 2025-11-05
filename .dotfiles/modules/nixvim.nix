{ config, pkgs, ... }:
{
  programs.nixvim = {
    enable = true;
    
    colorschemes.catppuccin = {
      enable = true;
      settings.flavour = "macchiato";
    };
    
    opts = {
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
      smartindent = true;
      clipboard = "unnamedplus";
    };
    
    plugins = {
      web-devicons.enable = true;
      
      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
        };
      };
      
      telescope = {
        enable = true;
        keymaps = {
          "<leader>ff" = {
            action = "find_files";
            options.desc = "Find files";
          };
          "<leader>fg" = {
            action = "live_grep";
            options.desc = "Live grep";
          };
          "<leader>fb" = {
            action = "buffers";
            options.desc = "Buffers";
          };
          "<leader>fh" = {
            action = "help_tags";
            options.desc = "Help tags";
          };
        };
      };
    };
    
    globals.mapleader = " ";
  };
}