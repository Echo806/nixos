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

    agency-agents = {
      url = "github:msitarzewski/agency-agents";
      flake = false;
    };

    superpowers = {
      url = "github:obra/superpowers";
      flake = false;
    };

    anthropic-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };

    openai-skills = {
      url = "github:openai/skills";
      flake = false;
    };

    iorest-rime-dict = {
      url = "github:Iorest/rime-dict";
      flake = false;
    };

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
      localOverlays = [
        (final: prev: {
          maple-mono-custom = prev.callPackage ./assets/fonts/maple-mono-custom { };
          windows-fonts = prev.callPackage ./assets/fonts/windows-fonts { };
          bb-browser = prev.callPackage ./home/agent/tools/bb-browser { };
          agentmemory = prev.callPackage ./home/agent/tools/agentmemory { };
          claude-code = prev.callPackage ./home/agent/tools/claude-code { };
          codex = prev.callPackage ./home/agent/tools/codex { };
          opencode = prev.callPackage ./home/agent/tools/opencode { };
          cli-anything-hub = prev.callPackage ./home/agent/tools/cli-anything-hub.nix { };
        })
      ];
      mkHomeManager = homeHostPath: {
        home-manager.useGlobalPkgs = false;
        home-manager.useUserPackages = true;
        home-manager.users.run = { pkgs, ... }: {
          _module.args.pkgsPath = inputs.nixpkgs;
          nixpkgs = {
            config.allowUnfree = true;
            overlays = localOverlays;
          };
          imports = [
            noctalia.homeModules.default
            homeHostPath
          ];
        };
        home-manager.extraSpecialArgs = {
          inherit inputs;
          lib = import (inputs.home-manager.outPath + "/modules/lib/stdlib-extended.nix") inputs.nixpkgs.lib;
        };
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
              nixpkgs.overlays = localOverlays;
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
              nixpkgs.overlays = localOverlays;
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
