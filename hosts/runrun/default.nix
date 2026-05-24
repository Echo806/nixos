{ config, pkgs, inputs, ... }:
let
  fonts = import ../../assets/fonts { inherit pkgs; };
in
{
  imports = [
    ./hardware.nix
    ../../system/base/sudo-askpass.nix
    ../../system/base/users.nix
    ../../system/base/locale.nix
    ../../system/base/nix-settings.nix
    ../../system/base/fonts.nix
    ../../system/desktop/niri.nix
    ../../system/desktop/noctalia.nix
    ../../system/hardware/bluetooth.nix
    ../../system/hardware/audio.nix
    ../../system/hardware/power.nix
    ../../system/services/printing.nix
    ../../system/services/hermes-agent.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # LTS 内核
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  # 禁用 systemd-based initrd（ThinkPad X250 Broadwell 上崩溃）
  boot.initrd.systemd.enable = false;

  # Networking
  networking.hostName = "runrun";
  networking.proxy.default = "http://127.0.0.1:7897/";
  networking.proxy.noProxy = "127.0.0.1,localhost";
  networking.networkmanager.enable = true;

  # System-level programs
  programs.steam.enable = true;
  programs.steam.fontPackages = fonts.steam;
  programs.clash-verge.enable = true;

  services.tailscale.enable = true;
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };


  environment.systemPackages = with pkgs; [
    wget
    git
    polkit_gnome
    networkmanagerapplet
    gnome-keyring
    xwayland-satellite
  ];

  system.stateVersion = "25.11";
}
