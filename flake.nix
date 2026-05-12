{
  description = "NixOS configuration with niri + Noctalia";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    llm-agents.url = "github:numtide/llm-agents.nix";

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
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

  outputs = inputs@{ self, nixpkgs, home-manager, nixos-hardware, noctalia, ... }:
  let
    mkHomeManager = homeHostPath: {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.run.imports = [
        noctalia.homeModules.default
        homeHostPath
      ];
      home-manager.extraSpecialArgs = { inherit inputs; };
    };
  in {
    nixosConfigurations = {
      # ThinkPad X250 — 当前主力机
      x250 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ({ ... }: {
            nixpkgs.overlays = [
              (final: prev: {
                wps-symbol-fonts = prev.callPackage ./packages/wps-symbol-fonts { };
              })
            ];
          })
          ./hosts/x250
          home-manager.nixosModules.home-manager
          (mkHomeManager ./home/hosts/x250.nix)
        ];
      };

      # Lenovo Legion R9000P — 待添加
      # r9000p = nixpkgs.lib.nixosSystem {
      #   system = "x86_64-linux";
      #   specialArgs = { inherit inputs; };
      #   modules = [
      #     ./hosts/r9000p
      #     home-manager.nixosModules.home-manager
      #     (mkHomeManager ./home/hosts/r9000p.nix)
      #   ];
      # };
    };
  };
}
