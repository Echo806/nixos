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
    # Keep the service/package/config available, but do not start at boot.
    # Start manually when needed with: sudo systemctl start openlist
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

  # Let the openlist service account list /home/run when the Local storage root
  # points there. Keep the home directory non-world-readable, but grant this
  # one service user read/traverse access declaratively.
  systemd.tmpfiles.rules = [
    "a /home/run - - - - u::rwx,u:openlist:rx,g::--x,m::rx,o::--x"
  ];

  # OpenList default HTTP port. This makes it reachable on LAN/tailnet for the
  # experiment; do not expose it directly to the public Internet.
  networking.firewall.allowedTCPPorts = [ 5244 ];

  environment.systemPackages = with pkgs; [
    openlist
  ];
}
