{ config, pkgs, inputs, lib, ... }:
let
  fonts = import ../../assets/fonts { inherit pkgs; };
  # Keep NO_PROXY entries to host/domain names and IPv4 CIDRs.  Python httpx
  # treats IPv6 CIDR literals here as host:port strings and raises e.g.
  # "Invalid port: '115c:a1e0::'", which breaks Hermes auxiliary calls.
  tailnetNoProxy = "127.0.0.1,localhost,.tailnet.tomandjerry2026.xyz,desktop.tailnet.tomandjerry2026.xyz,100.64.0.0/10";
in
{
  imports = [
    ./hardware.nix
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x250
    ../../system/base/sudo-askpass.nix
    ../../system/base/users.nix
    ../../system/base/locale.nix
    ../../system/base/input-method.nix
    ../../system/base/nix-settings.nix
    ../../system/base/fonts.nix
    ../../system/desktop/niri.nix
    ../../system/desktop/clipboard-bridge.nix
    ../../system/desktop/noctalia.nix
    ../../system/hardware/bluetooth.nix
    ../../system/hardware/audio.nix
    ../../system/hardware/power.nix
    ../../system/services/printing.nix
    ../../system/services/sshfs.nix
    ../../system/services/openlist.nix
    ../../system/services/cloudflared-openlist.nix
    ../../home/apps/hermes/system.nix
    ../../system/services/office-tools.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # LTS 内核
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  # Keep the normal boot path on scripted initrd for now: systemd initrd
  # previously crashed on this ThinkPad X250 Broadwell.  NixOS warns that
  # scripted initrd is deprecated, so expose a separate boot-menu test entry
  # below before changing the default.
  boot.initrd.systemd.enable = false;

  specialisation.systemd-initrd-test.configuration = {
    # Boot-menu-only test generation.  The default x250 entry remains on the
    # known-good scripted initrd, so a failed test can be recovered by simply
    # rebooting into the normal/default generation.
    # Current hypothesis for the no-log black screen: systemd initrd's default
    # TPM2/FIDO2 early-boot integration may hang on this old X250 firmware/TPM
    # before systemd can show status or persist logs. Keep the normal/default
    # boot entry unchanged; disable these only in this diagnostic entry.
    boot.initrd.systemd = {
      enable = lib.mkForce true;
      tpm2.enable = lib.mkForce false;
      fido2.enable = lib.mkForce false;
      # If stage-1 fails, drop to an unauthenticated initrd emergency shell
      # instead of silently hanging on a black screen.  This applies only to
      # this specialisation test entry, not the normal/default boot entry.
      emergencyAccess = lib.mkForce true;
    };
    boot.consoleLogLevel = lib.mkForce 7;
    boot.kernelParams = [
      # QEMU can start this same kernel/initrd and reaches systemd initrd,
      # while the real X250 still goes black before any persistent journal.
      # Test the display/KMS hypothesis next: keep early boot on firmware
      # framebuffer instead of allowing i915 KMS takeover in initrd.
      "nomodeset"
      "debug"
      "console=tty0"
      "systemd.crash_chvt=1"
      "systemd.default_standard_output=journal+console"
      "systemd.default_standard_error=journal+console"
      "systemd.log_level=debug"
      "systemd.log_target=console"
      "systemd.show_status=1"
      "rd.systemd.debug_shell=tty9"
      "rd.systemd.default_debug_tty=tty9"
      "rd.systemd.break=pre-mount"
    ];
  };

  # Networking
  networking.hostName = "x250";
  networking.proxy.default = "http://127.0.0.1:7897/";
  # Do not send tailnet/MagicDNS traffic through Clash; it must route directly
  # over tailscale0 to services such as desktop:8328.
  networking.proxy.noProxy = tailnetNoProxy;
  environment.sessionVariables = {
    no_proxy = tailnetNoProxy;
    NO_PROXY = tailnetNoProxy;
  };
  networking.networkmanager = {
    enable = true;
    # Let systemd-resolved handle split DNS instead of letting resolvconf
    # flatten all DNS servers into /etc/resolv.conf.
    dns = "systemd-resolved";
  };

  services.resolved = {
    enable = true;
    # Public DNS fallback only; per-link DNS from NetworkManager and Tailscale
    # is still preferred when available.
    settings.Resolve.FallbackDNS = [ "1.1.1.1" "8.8.8.8" ];
  };

  # System-level programs
  programs.steam.enable = true;
  programs.steam.fontPackages = fonts.steam;
  programs.clash-verge.enable = true;

  services.tailscale = {
    enable = true;
    # With systemd-resolved enabled, Tailscale can install split DNS routes:
    # only *.tailnet.tomandjerry2026.xyz goes to MagicDNS, while ordinary
    # domains such as github.com continue to use the current network's DNS.
    extraSetFlags = [ "--accept-dns=true" ];
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
      PermitRootLogin = "yes";
    };
  };

  # Removable drives in file managers and automatic USB mounting.
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.devmon.enable = true;

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
    wl-clipboard
    xclip
  ];

  system.stateVersion = "25.11";
}
