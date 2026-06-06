{ config, pkgs, ... }:

# bb-browser daemon — provides WebSocket bridge between Chrome extension and CLI
# Start with: systemctl --user start bb-browser-daemon
# Or just use: bb-browser daemon start
{
  systemd.user.services.bb-browser-daemon = {
    description = "bb-browser daemon (Chrome CDP bridge)";
    after = [ "graphical-session.target" ];
    wantedBy = [ ];  # manual start, not auto-start

    serviceConfig = {
      ExecStart = "${pkgs.bb-browser}/bin/bb-browser-daemon";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
