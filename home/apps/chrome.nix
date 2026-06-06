{ config, pkgs, ... }:

let
  chrome-remote = pkgs.writeShellApplication {
    name = "google-chrome-remote";
    runtimeInputs = [ pkgs.google-chrome ];
    text = ''
      exec google-chrome \
        --remote-debugging-port=9222 \
        --proxy-server="http://127.0.0.1:7897" \
        "$@"
    '';
  };
in
{
  home.packages = with pkgs; [
    google-chrome
    chrome-remote
  ];

  # Chrome managed policies — proxy for bb-browser
  xdg.configFile."chrome/policies/managed/proxy.json".text = builtins.toJSON {
    ProxyMode = "fixed_servers";
    ProxyServer = "http://127.0.0.1:7897";
  };
}
