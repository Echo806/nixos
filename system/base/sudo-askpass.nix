{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.x11_ssh_askpass ];

  environment.etc."sudo.conf".text = ''
    Path askpass ${pkgs.x11_ssh_askpass}/libexec/x11-ssh-askpass
  '';

  environment.variables.SUDO_ASKPASS = "${pkgs.x11_ssh_askpass}/libexec/x11-ssh-askpass";
}
