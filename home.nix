{ config, pkgs, ... }:

{
  # 注意修改这里的用户名与用户目录
  home.username = "run";
  home.homeDirectory = "/home/run";

  # 将当前配置目录中的文件导入 Nix store，并在 Home 目录下生成指向该 store 文件的符号链接
  # home.file.".config/i3/wallpaper.jpg".source = ./wallpaper.jpg;

  # 将 scripts 目录导入 Nix store，并在 Home 目录下递归生成指向 store 中的文件的符号链接
  # home.file.".config/i3/scripts" = {
  #   source = ./scripts;
  #   recursive = true;   # 递归整个文件夹
  #   executable = true;  # 将其中所有文件添加「执行」权限
  # };

  # 直接以 text 的方式，在 nix 配置文件中硬编码文件内容
  # home.file.".xxx".text = ''
  #     xxx
  # '';

  # 设置鼠标指针大小以及字体 DPI（适用于 4K 显示器）
  xresources.properties = {
    "Xcursor.size" = 16;
    "Xft.dpi" = 172;
  };



  # 通过 home.packages 安装一些常用的软件
  # 这些软件将仅在当前用户下可用，不会影响系统级别的配置
  # 建议将所有 GUI 软件，以及与 OS 关系不大的 CLI 软件，都通过 home.packages 安装
  home.packages = with pkgs;[
    steam
    claude-code    
    qq
    splayer
    codex
    vscode
    #wechat

  ];


  programs.git = {
    enable = true;
    settings={
      user={
        email="2535212471@qq.com";
        name="Echo806";
      };
    };
  };


  # Note: Configure API keys and sensitive settings outside of this file
  # Store them in environment variables or use a secure secrets management system
  # Uncomment and configure proxy if needed:
  home.sessionVariables = {
    http_proxy = "http://127.0.0.1:7897";
    https_proxy = "http://127.0.0.1:7897";
    all_proxy = "socks5:127.0.0.1:7897";
  };


  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.11";

  # Enable programs module for home-manager
  programs.home-manager.enable = true;
}
