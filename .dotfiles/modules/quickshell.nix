{ quickshell-pkg, ... }:
{
  home.packages = [ quickshell-pkg ];

  xdg.configFile."quickshell" = {
    source = ../quickshell;
    recursive = true;
  };
}
