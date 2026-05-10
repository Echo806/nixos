{ config, pkgs, inputs, ... }:

{
  home.packages =
    (with pkgs; [
      claude-code
    ])
    ++ [
      inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.cc-switch-cli
    ];

  home.file."CLAUDE.md".source = ../../CLAUDE.md;
  home.file."keybindings.md".source = ../../keybindings.md;
}
