{
  description = "NixOS configuration with niri + Noctalia";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    llm-agents.url = "github:numtide/llm-agents.nix";

    # Noctalia shell / desktop environment
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home-manager (master, 对齐 nixpkgs-unstable)
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Binary caches
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

  outputs = inputs@{ self, nixpkgs, home-manager, nixos-hardware, noctalia, ... }: {
    nixosConfigurations = {
      # 这里的 my-nixos 替换成你的主机名称
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          ./noctalia.nix
          nixos-hardware.nixosModules.lenovo-thinkpad-x250
          # 将 home-manager 配置为 nixos 的一个 module
          # 这样在 nixos-rebuild switch 时，home-manager 配置也会被自动部署
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            # 使用 imports 方式加载 home.nix, 以便在其中引入 noctalia homeModules
            home-manager.users.run = {
              imports = [
                inputs.noctalia.homeModules.default
                ./home.nix
              ];
            };

            # 使用 home-manager.extraSpecialArgs 自定义传递给 ./home.nix 的参数
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };
    };
  };
}
