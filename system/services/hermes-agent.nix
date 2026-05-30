{ config, pkgs, inputs, ... }:
let
  hermes = import ../../hermes { inherit pkgs inputs; };
in
{
  users.groups.hermes = { };
  users.users.hermes = {
    isSystemUser = true;
    group = "hermes";
    home = "/var/lib/hermes";
    createHome = true;
  };

  imports = [
    inputs.hermes-agent.nixosModules.default
  ];

  systemd.tmpfiles.rules = hermes.tmpfilesRules;

  services.hermes-agent = {
    # The user no longer wants QQ/social-media integration, so do not run the
    # always-on messaging gateway service. Keep CLI/config/skills below managed
    # explicitly for normal local Hermes use.
    enable = false;

    settings = hermes.settings;

    # 密钥走环境文件（/var/lib/hermes/env），不在 Git 中跟踪
    environmentFiles = [ "/var/lib/hermes/env" ];
  };

  environment.systemPackages = hermes.packages;

  environment.variables = {
    HERMES_HOME = "/var/lib/hermes/.hermes";
  };
}
