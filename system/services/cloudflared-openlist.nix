{ pkgs, ... }:

{
  # Trial Cloudflare Tunnel for x250 OpenList. The token is intentionally kept
  # out of git. Create /var/lib/cloudflared/openlist-token as a root-only file
  # containing the token from the Cloudflare Zero Trust dashboard.
  users.groups.cloudflared = { };
  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
    home = "/var/lib/cloudflared";
    createHome = true;
  };

  systemd.services.cloudflared-openlist = {
    description = "Cloudflare Tunnel for OpenList at runrunnas.ccwu.cc";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "openlist.service" ];
    wants = [ "network-online.target" "openlist.service" ];
    unitConfig.ConditionPathExists = "/var/lib/cloudflared/openlist-token";
    serviceConfig = {
      User = "cloudflared";
      Group = "cloudflared";
      StateDirectory = "cloudflared";
      # The token identifies a remotely-managed Cloudflare Tunnel. Configure the
      # Public Hostname in Cloudflare Zero Trust as:
      #   runrunnas.ccwu.cc -> HTTP http://localhost:5244
      # Keep --url here too so this connector has an explicit local origin while
      # the tunnel is being tested from x250.
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token-file /var/lib/cloudflared/openlist-token --url http://127.0.0.1:5244";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  environment.systemPackages = with pkgs; [
    cloudflared
  ];
}
