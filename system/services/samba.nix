{ config, pkgs, ... }:

{
  services.samba = {
    enable = true;
    openFirewall = true;

    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "runrun Samba Server";
        "netbios name" = config.networking.hostName;
        "security" = "user";
        "map to guest" = "Bad User";
        "server min protocol" = "SMB2";
        "hosts allow" = "192.168.0.0/16 10.0.0.0/8 172.16.0.0/12 100.64.0.0/10 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
      };

      share = {
        "path" = "/home/run/share";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "run";
        "force user" = "run";
        "force group" = "users";
        "create mask" = "0664";
        "directory mask" = "0775";
      };
    };
  };

  # Make the Samba host discoverable from Windows File Explorer's Network view.
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  systemd.tmpfiles.rules = [
    "d /home/run/share 0775 run users - -"
  ];
}
