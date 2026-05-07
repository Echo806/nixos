{ config, pkgs, inputs, ... }:

{
  home.packages =
    (with pkgs; [
      claude-code
    ])
    ++ [
      inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.cc-switch-cli
    ];
}
