{ config, pkgs, ... }:

{
  users.users.run = {
    isNormalUser = true;
    description = "run";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
      clash-verge-rev
    ];
  };
}
