{ config, ... }:

{
  # Keep the system PATH binary in sync with the Home Manager service package.
  # Niri keybindings spawn "noctalia-shell" from PATH, and Quickshell IPC is
  # keyed by QS_CONFIG_PATH, so a second system-level build cannot control the
  # running Home Manager instance.
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
