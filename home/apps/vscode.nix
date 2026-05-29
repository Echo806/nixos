{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    vscode
  ];

  xdg.configFile."Code/User/settings.json".text = builtins.toJSON {
    "editor.fontFamily" = "Maple Mono Custom, Microsoft YaHei Mono, Noto Sans Mono CJK SC, monospace";
    "editor.fontLigatures" = false;
    "terminal.integrated.fontFamily" = "Maple Mono Custom, Microsoft YaHei Mono, Noto Sans Mono CJK SC, monospace";
  };
}
