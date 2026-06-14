{ config, pkgs, inputs, ... }:

let
  noctaliaBase = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  noctaliaShell = pkgs.runCommand "noctalia-shell-tray-names" {
    nativeBuildInputs = [ pkgs.python3 ];
  } ''
    cp -a ${noctaliaBase}/. $out/
    chmod u+w \
      $out/share/noctalia-shell/Modules/Bar/Widgets/Tray.qml \
      $out/share/noctalia-shell/Modules/Panels/Tray/TrayDrawerPanel.qml

    python3 - <<'PY'
import os
from pathlib import Path

out = Path(os.environ["out"])
tray = out / "share/noctalia-shell/Modules/Bar/Widgets/Tray.qml"
drawer = out / "share/noctalia-shell/Modules/Panels/Tray/TrayDrawerPanel.qml"

def patch_once(path, old, new):
    text = path.read_text()
    if old not in text:
        raise SystemExit(f'missing pattern in {path}: {old!r}')
    path.write_text(text.replace(old, new, 1))

tray_func = """
  function trayDisplayName(item) {
    if (!item) return "Tray Item";
    const raw = [item.tooltipTitle || "", item.name || "", item.id || "", item.icon || ""].join(" ").toLowerCase();
    if (raw.includes("clash") || raw.includes("tray-icon") || raw.includes("icon_1") || raw.includes("icon-1")) return "clash-verge";
    if (raw.includes("chrome_status_icon") || raw.includes("chrome-status-icon") || raw === "qq") return "QQ";
    if (raw.includes("wechat")) return "WeChat";
    if (raw.includes("sunshine")) return "Sunshine";
    return item.tooltipTitle || item.name || item.id || "Tray Item";
  }
"""
patch_once(tray, '  function _performFilteredItemsUpdate() {', tray_func + '\n  function _performFilteredItemsUpdate() {')
text = tray.read_text()
text = text.replace('const title = item.tooltipTitle || item.name || item.id || "";', 'const title = root.trayDisplayName(item);')
text = text.replace('const title2 = item2.tooltipTitle || item2.name || item2.id || "";', 'const title2 = root.trayDisplayName(item2);')
text = text.replace('TooltipService.show(tooltipAnchor, modelData.tooltipTitle || modelData.name || modelData.id || "Tray Item", BarService.getTooltipDirection(root.screen?.name));', 'TooltipService.show(tooltipAnchor, root.trayDisplayName(modelData), BarService.getTooltipDirection(root.screen?.name));')
tray.write_text(text)

drawer_func = """
  function trayDisplayName(item) {
    if (!item) return "Tray Item";
    const raw = [item.tooltipTitle || "", item.name || "", item.id || "", item.icon || ""].join(" ").toLowerCase();
    if (raw.includes("clash") || raw.includes("tray-icon") || raw.includes("icon_1") || raw.includes("icon-1")) return "clash-verge";
    if (raw.includes("chrome_status_icon") || raw.includes("chrome-status-icon") || raw === "qq") return "QQ";
    if (raw.includes("wechat")) return "WeChat";
    if (raw.includes("sunshine")) return "Sunshine";
    return item.tooltipTitle || item.name || item.id || "Tray Item";
  }
"""
patch_once(drawer, '  // Auto-close drawer when all items are pinned (drawer becomes empty)', drawer_func + '\n  // Auto-close drawer when all items are pinned (drawer becomes empty)')
text = drawer.read_text()
text = text.replace('const title = item?.tooltipTitle || item?.name || item?.id || "";', 'const title = root.trayDisplayName(item);')
text = text.replace('TooltipService.show(trayIcon, modelData.tooltipTitle || modelData.name || modelData.id || "Tray Item", BarService.getTooltipDirection(root.screen?.name));', 'TooltipService.show(trayIcon, root.trayDisplayName(modelData), BarService.getTooltipDirection(root.screen?.name));')
drawer.write_text(text)
PY
  '';
in
{
  # 将 noctalia-shell 安装到系统级环境
  environment.systemPackages = [
    noctaliaShell
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
