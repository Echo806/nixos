{ config, pkgs, ... }:

{
  users.users.run = {
    isNormalUser = true;
    description = "run";
    homeMode = "0711";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
      clash-verge-rev
    ];
  };
}
