{ config, pkgs, inputs, ... }:

{
  imports = [
    ../system/base/sudo-askpass.nix
    ../system/base/users.nix
    ../system/base/locale.nix
    ../system/base/nix-settings.nix
    ../system/services/sshfs.nix
  ];

  networking.hostName = "nas";
  networking.networkmanager.enable = true;

  # NAS should be reachable privately from the tailnet; public access goes via
  # Cloudflare Tunnel, so no WAN port-forwarding is required.
  services.tailscale.enable = true;

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
      PermitRootLogin = "yes";
    };
  };

  # OpenList is packaged in nixpkgs but currently has no built-in NixOS module
  # in this channel, so run it as a small dedicated systemd service.
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

  # OpenList listens on 5244 by default. Keep it available on LAN/tailnet;
  # Cloudflare Tunnel will publish the chosen public hostname.
  networking.firewall.allowedTCPPorts = [ 5244 ];

  # Cloudflare Tunnel token is intentionally not stored in git. On the NAS,
  # create /var/lib/cloudflared/tunnel-token containing the token from the
  # Cloudflare Zero Trust dashboard. The service will then proxy OpenList.
  users.groups.cloudflared = { };
  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
    home = "/var/lib/cloudflared";
    createHome = true;
  };

  systemd.services.cloudflared-openlist = {
    description = "Cloudflare Tunnel for OpenList";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "openlist.service" ];
    wants = [ "network-online.target" "openlist.service" ];
    serviceConfig = {
      User = "cloudflared";
      Group = "cloudflared";
      StateDirectory = "cloudflared";
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token-file /var/lib/cloudflared/tunnel-token --url http://127.0.0.1:5244";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  # Future mount plan: after x250/runrun hostnames and SSH keys are fixed,
  # add declarative sshfs mounts under /mnt/x250 and /mnt/runrun using
  # fileSystems.<mountpoint>.device = "run@<host>:/path" and fsType = "sshfs".
  # Tailscale hostnames are preferred over public IPs.

  environment.systemPackages = with pkgs; [
    wget
    git
    vim
    openlist
    cloudflared
    sshfs
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  system.stateVersion = "25.11";
}
