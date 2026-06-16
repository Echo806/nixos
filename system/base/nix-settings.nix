{ config, pkgs, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];

    extra-substituters = [
      "https://cache.garnix.io"
      "https://attic.xuyh0120.win/lantian"
      "https://noctalia.cachix.org"
    ];

    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  nixpkgs.config.allowUnfree = true;

  # Keep the conventional NixOS config path writable and pointed at the live
  # user-owned flake checkout instead of a stale / missing location.
  system.activationScripts.nixosSourceLink.text = ''
    if [ -L /etc/nixos ] || [ ! -e /etc/nixos ]; then
      ln -sfn /home/run/nixos /etc/nixos
    else
      echo "/etc/nixos exists and is not a symlink; refusing to replace it" >&2
      exit 1
    fi
  '';
}
