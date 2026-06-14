{
  description = "NixOS configuration with niri + Noctalia";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # X250 needs the old scripted initrd path: systemd initrd black-screens on
    # this Broadwell ThinkPad with no journal/pstore. Keep a separate nixpkgs
    # input so other hosts can move forward while x250 stays on a known-good
    # pre-removal implementation if/when scripted initrd disappears upstream.
    nixpkgs-x250-legacy.url = "github:nixos/nixpkgs/549bd84d6279f9852cae6225e372cc67fb91a4c1";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    llm-agents.url = "github:numtide/llm-agents.nix";

    hermes-agent.url = "github:NousResearch/hermes-agent";

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-x250-legacy, home-manager, nixos-hardware, noctalia, ... }:
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
    in
    {
      nixosConfigurations = {
        # ThinkPad X250 — 当前主力机
        x250 = nixpkgs-x250-legacy.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; pkgsUnstable = nixpkgs.legacyPackages.x86_64-linux; };
          modules = [
            ({ ... }: {
              nixpkgs.overlays = [
                (final: prev: {
                  maple-mono-custom = prev.callPackage ./assets/fonts/maple-mono-custom { };
                  windows-fonts = prev.callPackage ./assets/fonts/windows-fonts { };
                  bb-browser = prev.callPackage ./agent/tools/bb-browser { };
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
        runrun = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ({ ... }: {
              nixpkgs.overlays = [
                (final: prev: {
                  maple-mono-custom = prev.callPackage ./assets/fonts/maple-mono-custom { };
                  windows-fonts = prev.callPackage ./assets/fonts/windows-fonts { };
                  bb-browser = prev.callPackage ./agent/tools/bb-browser { };
                })
              ];
            })
            ./hosts/runrun
            home-manager.nixosModules.home-manager
            (mkHomeManager ./home/hosts/runrun.nix)
          ];
        };

        # NAS — OpenList + Cloudflare Tunnel entrypoint
        nas = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/nas.nix
          ];
        };
      };
    };
}
