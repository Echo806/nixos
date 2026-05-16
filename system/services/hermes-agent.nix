{ config, pkgs, inputs, ... }:
{
  imports = [
    inputs.hermes-agent.nixosModules.default
  ];

  services.hermes-agent = {
    enable = true;

    settings = {
      model = {
        base_url = "https://openrouter.ai/api/v1";
        default = "deepseek/deepseek-v4-flash:free";
      };
      toolsets = [ "all" ];
    };

    # 密钥走环境文件（/var/lib/hermes/env），不在 Git 中跟踪
    environmentFiles = [ "/var/lib/hermes/env" ];

    addToSystemPackages = true;
  };
}
