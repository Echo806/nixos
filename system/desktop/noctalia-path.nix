{ config, ... }:

{
  # PATH bridge for Niri keybindings.
  #
  # The real Noctalia Shell package, settings, and user service live in Home
  # Manager. Niri spawns "noctalia-shell" from the system PATH, so expose that
  # exact Home Manager package here instead of building a second system-level
  # Noctalia instance. Quickshell IPC is keyed by QS_CONFIG_PATH, so using a
  # different package here would not control the running user service.
  environment.systemPackages = [
    config.home-manager.users.run.programs.noctalia-shell.package
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
