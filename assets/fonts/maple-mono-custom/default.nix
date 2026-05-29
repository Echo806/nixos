{ lib, stdenvNoCC, fetchurl, python3Packages }:

stdenvNoCC.mkDerivation rec {
  pname = "maple-mono-custom";
  version = "7.9";

  src = fetchurl {
    url = "https://github.com/subframe7536/Maple-font/releases/download/v${version}/MapleMonoNL-NF-CN.zip";
    hash = "sha256-YQPTpz0Ald5rNOcJ8+yvEUfjWrdxfAMGjgfAuwqO+i4=";
  };

  dontUnpack = true;
  nativeBuildInputs = [
    python3Packages.fonttools
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype/maple-mono-custom

    python3 - <<'PY'
    import io
    import json
    import os
    from zipfile import ZipFile

    from fontTools.ttLib import TTFont

    SOURCE_ZIP = os.environ["src"]
    OUT_DIR = os.path.join(os.environ["out"], "share/fonts/truetype/maple-mono-custom")

    # Same feature-freeze choices generated at https://font.subf.dev/zh-cn/playground/:
    # --no-liga --cn --feat cv01,cv03,cv06,cv32,cv34,cv35,cv36,cv39,cv40,cv61,ss01,ss02,ss04
    # The source archive is already the upstream no-ligature + Nerd Font + CN build;
    # this step bakes the selected OpenType alternates into the installed TTFs.
    CONFIG = {
        "calt": "0",
        "cv01": "1",
        "cv03": "1",
        "cv06": "1",
        "cv32": "1",
        "cv34": "1",
        "cv35": "1",
        "cv36": "1",
        "cv39": "1",
        "cv40": "1",
        "cv61": "1",
        "ss01": "1",
        "ss02": "1",
        "ss04": "1",
    }
    MOVING_RULES = ["ss03", "ss07", "ss08", "ss09", "ss10", "ss11"]

    def freeze_config_suffix(config):
        suffix = ""
        for feature, state in sorted(config.items()):
            if state == "1":
                suffix += f"+{feature};"
            if (feature == "calt" and state == "0") or state == "-1":
                suffix += f"-{feature};"
        return suffix

    def freeze_feature(font, moving_rules, config):
        gsub = font["GSUB"].table
        feature_list = gsub.FeatureList
        records = feature_list.FeatureRecord
        features = {
            record.FeatureTag: (index, record.Feature)
            for index, record in enumerate(records)
            if record.FeatureTag != "calt"
        }
        calt_features = [record.Feature for record in records if record.FeatureTag == "calt"]
        calt_enabled = config.get("calt") == "1"

        if not calt_enabled:
            for feature in calt_features:
                feature.LookupListIndex.clear()
                feature.LookupCount = 0

        remove_record_indexes = []
        for tag, state in config.items():
            if tag not in features or state == "0":
                continue
            record_index, feature = features[tag]
            if state == "-1":
                remove_record_indexes.append(record_index)
                continue
            if tag in moving_rules and calt_enabled:
                for calt_feature in calt_features:
                    calt_feature.LookupListIndex.extend(feature.LookupListIndex)
            else:
                glyphs = font["glyf"].glyphs
                metrics = font["hmtx"].metrics
                for lookup_index in feature.LookupListIndex:
                    lookup = gsub.LookupList.Lookup[lookup_index]
                    for subtable in lookup.SubTable:
                        mapping = getattr(subtable, "mapping", None)
                        if not mapping:
                            continue
                        for source, target in mapping.items():
                            if source in glyphs and source in metrics and target in glyphs and target in metrics:
                                glyphs[source] = glyphs[target]
                                metrics[source] = metrics[target]

        for record_index in sorted(remove_record_indexes, reverse=True):
            records[record_index].Feature.LookupCount = 0
            records[record_index].Feature.LookupListIndex = []

    def get_name(font, name_id):
        name = font["name"].getName(nameID=name_id, platformID=3, platEncID=1, langID=1033)
        return name.toUnicode() if name is not None else ""

    def set_name(font, value, name_id):
        font["name"].setName(value, nameID=name_id, platformID=3, platEncID=1, langID=1033)

    def make_custom_regular_from_italic(font, weight_name, weight_value):
        # Make the upstream Italic outlines appear to applications as a normal
        # family/style.  Some terminal renderers only use italic faces when the
        # terminal application emits italic text; the web preview, however,
        # displays the selected Italic sample as the primary face.  This custom
        # family forces that same hand-written italic outline for normal text.
        family = "Maple Mono Custom"
        style = "Regular" if weight_name == "Regular" else weight_name
        full_name = f"{family} {style}" if style != "Regular" else family
        ps_style = style.replace(" ", "")
        postscript = f"MapleMonoCustom-{ps_style}"

        for name_id, value in {
            1: family,          # Font Family name
            2: style,           # Font Subfamily name
            3: postscript,      # Unique font identifier
            4: full_name,       # Full font name
            6: postscript,      # PostScript name
            16: family,         # Typographic family name
            17: style,          # Typographic subfamily name
        }.items():
            set_name(font, value, name_id)

        if "OS/2" in font:
            font["OS/2"].usWeightClass = weight_value
            font["OS/2"].fsSelection &= ~0x01  # clear ITALIC
            font["OS/2"].fsSelection |= 0x40   # set REGULAR where accepted
        if "head" in font:
            font["head"].macStyle &= ~0x02     # clear italic bit

    WEIGHTS = {
        "Thin": 100,
        "ExtraLight": 200,
        "Light": 300,
        "Regular": 400,
        "Medium": 500,
        "SemiBold": 600,
        "Bold": 700,
        "ExtraBold": 800,
    }

    suffix = freeze_config_suffix(CONFIG)
    with ZipFile(SOURCE_ZIP, "r") as archive:
        for entry in archive.infolist():
            if not entry.filename.lower().endswith(".ttf"):
                continue
            base = os.path.basename(entry.filename)
            if not base.endswith("Italic.ttf"):
                continue

            print(f"patching {entry.filename}")
            with archive.open(entry) as handle:
                font = TTFont(handle)
            freeze_feature(font, MOVING_RULES, CONFIG)

            # Expose every upstream Italic outline as a normal style in the
            # Maple Mono Custom family.  Ghostty can then use the
            # web-preview-like handwritten italic shape for ordinary terminal
            # text without relying on runtime italic selection.
            weight_name = base.removeprefix("MapleMonoNL-NF-CN-").removesuffix("Italic.ttf") or "Regular"
            if weight_name in WEIGHTS:
                make_custom_regular_from_italic(font, weight_name, WEIGHTS[weight_name])
                custom_target = os.path.join(OUT_DIR, f"MapleMonoCustom-{weight_name}.ttf")
                font.save(custom_target)

            font.close()

    with open(os.path.join(OUT_DIR, "maple-mono-custom-feature-freeze.json"), "w", encoding="utf-8") as handle:
        json.dump(CONFIG, handle, indent=2, ensure_ascii=False)
    PY

    runHook postInstall
  '';

  meta = with lib; {
    description = "Maple Mono NL NF CN with user's preferred OpenType feature freeze";
    homepage = "https://github.com/subframe7536/Maple-font";
    license = licenses.ofl;
    platforms = platforms.all;
  };
}
