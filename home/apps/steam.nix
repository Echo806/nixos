{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    steam
  ];

  # Steam's CEF UI hard-codes "Motiva Sans", Helvetica, sans-serif in many
  # places. On Linux it only reliably observes per-user fontconfig, and when
  # Motiva/Helvetica are chosen first they lack CJK glyphs, causing Chinese
  # usernames to render as tofu squares. Force those UI families to a CJK-capable
  # font for this user; system-level fonts.packages/programs.steam.fontPackages
  # alone are not enough for this path.
  xdg.configFile."fontconfig/conf.d/60-steam-cjk-fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <match target="pattern">
        <test name="family" compare="eq"><string>Motiva Sans</string></test>
        <edit name="family" mode="prepend" binding="strong"><string>Microsoft YaHei</string></edit>
      </match>
      <match target="pattern">
        <test name="family" compare="eq"><string>Helvetica</string></test>
        <edit name="family" mode="prepend" binding="strong"><string>Microsoft YaHei</string></edit>
      </match>
      <alias binding="strong">
        <family>sans-serif</family>
        <prefer>
          <family>Microsoft YaHei</family>
          <family>Noto Sans CJK SC</family>
        </prefer>
      </alias>
    </fontconfig>
  '';
}
