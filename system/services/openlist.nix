{ pkgs, ... }:

{
  # Trial OpenList service for x250. Keep this as a reusable module so the same
  # service can later move to the NAS host by importing this module there and
  # removing the x250 import.
  users.groups.openlist = { };
  users.users.openlist = {
    isSystemUser = true;
    group = "openlist";
    home = "/var/lib/openlist";
    createHome = true;
  };

  systemd.services.openlist = {
    description = "OpenList file listing service";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      User = "openlist";
      Group = "openlist";
      StateDirectory = "openlist";
      WorkingDirectory = "/var/lib/openlist";
      ExecStart = "${pkgs.openlist}/bin/OpenList --data /var/lib/openlist --log-std server";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  # OpenList default HTTP port. This makes it reachable on LAN/tailnet for the
  # experiment; do not expose it directly to the public Internet.
  networking.firewall.allowedTCPPorts = [ 5244 ];

  environment.systemPackages = with pkgs; [
    openlist
  ];
}
