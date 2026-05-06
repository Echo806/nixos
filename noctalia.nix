{ config, pkgs, inputs, ... }:

{
  # 将 noctalia-shell 安装到系统级环境
  environment.systemPackages = [
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # 日历支持 (可选——如需在 Noctalia 面板中显示日历事件请启用)
  # services.gnome.evolution-data-server.enable = true;
  # 然后需要 override 为带日历支持的版本:
  # environment.systemPackages = [
  #   (inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
  #     calendarSupport = true;
  #   })
  # ];
}
