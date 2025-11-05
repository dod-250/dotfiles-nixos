{ config, pkgs, ... }:
let
  myAliases = {
    ll = "ls -l";
    ".." = "cd ..";
  };
in
{

  programs.bash = {
    enable = true;
    shellAliases = myAliases;
  };

  programs.zsh = {
    enable = true;
    shellAliases = myAliases;
  };

  programs.fish = {
    enable = true;
    shellAliases = myAliases;
  };


}
