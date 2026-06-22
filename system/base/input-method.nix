{ config, lib, pkgs, ... }:

let
  # Rime schemas / dictionaries that should be available system-wide.
  # Keep input-method data here instead of Home Manager so x250/runrun share
  # the same reproducible Fcitx5/Rime setup.
  rimePackages = with pkgs; [
    rime-ice
    rime-zhwiki
    rime-moegirl
  ];

  rimeBaseData = "${pkgs.rime-data}/share/rime-data";
  rimeBaseDataDir = builtins.readDir rimeBaseData;
  rimeBaseDataFileEntries = lib.filter
    (name: rimeBaseDataDir.${name} == "regular")
    (builtins.attrNames rimeBaseDataDir);

  rimeIceData = "${pkgs.rime-ice}/share/rime-data";

  # Fcitx5/Rime on NixOS does not automatically see dictionaries that are only
  # installed as systemPackages. Seed the full rime-ice data tree into the user
  # data directory so manual redeploys can actually compile the rime_ice schema.
  rimeIceDataDir = builtins.readDir rimeIceData;
  rimeIceDataFileEntries = lib.filter
    (name: rimeIceDataDir.${name} == "regular")
    (builtins.attrNames rimeIceDataDir);
  rimeIceDataDirEntries = lib.filter
    (name: rimeIceDataDir.${name} == "directory")
    (builtins.attrNames rimeIceDataDir);

  rimeIceRegularEntriesIn = dirName:
    let entries = builtins.readDir "${rimeIceData}/${dirName}";
    in lib.filter
      (name: entries.${name} == "regular")
      (builtins.attrNames entries);

  rimeIceNestedDirEntries = lib.flatten (map
    (dirName:
      let entries = builtins.readDir "${rimeIceData}/${dirName}";
      in map
        (name: "${dirName}/${name}")
        (lib.filter (name: entries.${name} == "directory") (builtins.attrNames entries)))
    rimeIceDataDirEntries);

  rimeIceRegularEntriesInNested = dirPath:
    let entries = builtins.readDir "${rimeIceData}/${dirPath}";
    in lib.filter
      (name: entries.${name} == "regular")
      (builtins.attrNames entries);

  iorestRimeDict = pkgs.fetchFromGitHub {
    owner = "Iorest";
    repo = "rime-dict";
    rev = "a2057baecf53e5a45dfd5b72f1ec50773d8c9271";
    hash = "sha256-8XkMAy2PLu17kWexU9il6jPQNaDQ3IujFbr2bLno1QM=";
  };

  # Iorest/rime-dict is mostly Traditional Chinese. Convert its .dict.yaml files
  # to Simplified at build time so the full bundle works naturally with the
  # Simplified output mode of rime_ice, instead of relying on users to pick
  # Traditional candidates and mentally convert them.
  iorestDictFiles = lib.filter
    (name: lib.hasSuffix ".dict.yaml" name)
    (builtins.attrNames (builtins.readDir iorestRimeDict));

  iorestRimeDictSimplified = pkgs.runCommand "iorest-rime-dict-simplified"
    { nativeBuildInputs = [ pkgs.opencc ]; }
    ''
      mkdir -p "$out"
      for f in ${iorestRimeDict}/*.dict.yaml; do
        name="$(basename "$f")"
        opencc -c t2s.json -i "$f" -o "$out/$name"
      done
    '';

  openccData = "${pkgs.opencc}/share/opencc";
  openccDataEntries = builtins.attrNames (builtins.readDir openccData);

  managedTopLevelRimeFiles = rimeBaseDataFileEntries ++ rimeIceDataFileEntries ++ iorestDictFiles ++ [
    "default.custom.yaml"
    "rime_ice.custom.yaml"
    "run_ice.dict.yaml"
  ];

  # Keep the small Rime patch inline so this single module is the source of
  # truth for input-method behavior. If future Rime customization grows into
  # many schema/dict/lua files, split them back into system/base/rime/.
  rimeDefaultCustom = pkgs.writeText "default.custom.yaml" ''
    patch:
      __include: rime_ice_suggestion:/

      schema_list:
        - schema: rime_ice
  '';

  # Keep 雾凇拼音's original rime_ice dictionary. Its super-abbreviation prism is
  # what makes single initials and short forms work, e.g. d -> 的, ky -> 可以.
  # Replacing the dictionary with a merged full Iorest entry point breaks those
  # abbreviated candidates even though full spelling still works.
  rimeIceCustom = pkgs.writeText "rime_ice.custom.yaml" ''
    patch:
      # Remove rime-ice's English translators. With melt_eng enabled, typing a
      # single letter such as "d" surfaces English words before this host's
      # desired Chinese-only candidates.
      "schema/dependencies":
        - radical_pinyin
      "engine/translators":
        - punct_translator
        - script_translator
        - lua_translator@*date_translator
        - lua_translator@*lunar
        - lua_translator@*uuid
        - table_translator@custom_phrase
        - table_translator@radical_lookup
        - lua_translator@*unicode
        - lua_translator@*number_translator
        - lua_translator@*calc_translator
        - lua_translator@*force_gc
      # Remove emoji simplifier so candidates no longer include emoji
      "engine/filters":
        - lua_filter@*corrector
        - reverse_lookup_filter@radical_reverse_lookup
        - lua_filter@*autocap_filter
        - lua_filter@*v_filter
        - lua_filter@*pin_cand_filter
        - lua_filter@*long_word_filter
        - lua_filter@*reduce_english_filter
        - simplifier@traditionalize
        - lua_filter@*search@radical_pinyin
        - uniquifier
      # Remove emoji section entirely so it cannot be activated
      "emoji/__clear": true
  '';

  # Keep the generated run_ice entry point around for future experiments, but do
  # not use it as the active translator dictionary because it disables rime_ice's
  # short-code behavior.
  # Rime only compiled the immediate dictionaries imported by run_ice, so using
  # rime_ice + luna_pinyin.extended as nested entry points produced a tiny table
  # and let the English translator dominate. Import the real leaf dictionaries
  # directly so the compiled run_ice table contains Chinese words.
  rimeIceLeafTables = [
    "cn_dicts/8105"
    "cn_dicts/base"
    "cn_dicts/ext"
    "cn_dicts/tencent"
    "cn_dicts/others"
  ];

  iorestLeafTables = map
    (name: lib.removeSuffix ".dict.yaml" name)
    (lib.filter (name: name != "luna_pinyin.extended.dict.yaml") iorestDictFiles);

  runIceImportTables = rimeIceLeafTables ++ iorestLeafTables;

  runIceDict = pkgs.writeText "run_ice.dict.yaml" ''
    ---
    name: run_ice
    version: "1"
    sort: by_weight
    use_preset_vocabulary: true
    import_tables:
    ${lib.concatMapStringsSep "\n" (name: "  - ${name}") runIceImportTables}
    ...
  '';
in
{
  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;

    fcitx5.addons = with pkgs; [
      fcitx5-rime
      qt6Packages.fcitx5-chinese-addons
    ];
  };

  environment.systemPackages = rimePackages;

  # Declarative Rime user config for the normal desktop user.  Fcitx5/Rime reads
  # custom patches from ~/.local/share/fcitx5/rime; keep those seed files in git
  # so reinstalling the host reproduces the selected schema and dictionaries.
  systemd.tmpfiles.rules = [
    "d /home/run/.local/share/fcitx5/rime 0775 run users - -"
  ]
    # systemd-tmpfiles C/C+ does not overwrite existing files. Remove only the
    # files managed by this module first, then copy fresh store contents. This is
    # required when a dictionary source changes, for example after converting the
    # Iorest bundle from Traditional to Simplified.
    ++ map
      (name: "r /home/run/.local/share/fcitx5/rime/${name} - - - - -")
      managedTopLevelRimeFiles
    ++ [
      "r /home/run/.local/share/fcitx5/rime/opencc/* - - - - -"
      "r /home/run/.local/share/fcitx5/rime/cn_dicts/* - - - - -"
      "r /home/run/.local/share/fcitx5/rime/lua/cold_word_drop/* - - - - -"
      "C /home/run/.local/share/fcitx5/rime/default.custom.yaml 0664 run users - ${rimeDefaultCustom}"
      "C /home/run/.local/share/fcitx5/rime/rime_ice.custom.yaml 0664 run users - ${rimeIceCustom}"
      "C /home/run/.local/share/fcitx5/rime/run_ice.dict.yaml 0664 run users - ${runIceDict}"
    ]
    ++ map
      (name: "C /home/run/.local/share/fcitx5/rime/${name} 0664 run users - ${rimeBaseData}/${name}")
      rimeBaseDataFileEntries
    ++ map
      (name: "C /home/run/.local/share/fcitx5/rime/${name} 0664 run users - ${rimeIceData}/${name}")
      rimeIceDataFileEntries
    ++ map
      (name: "d /home/run/.local/share/fcitx5/rime/${name} 0775 run users - -")
      rimeIceDataDirEntries
    ++ lib.flatten (map
      (dirName: map
        (fileName: "C /home/run/.local/share/fcitx5/rime/${dirName}/${fileName} 0664 run users - ${rimeIceData}/${dirName}/${fileName}")
        (rimeIceRegularEntriesIn dirName))
      rimeIceDataDirEntries)
    ++ map
      (dirPath: "d /home/run/.local/share/fcitx5/rime/${dirPath} 0775 run users - -")
      rimeIceNestedDirEntries
    ++ lib.flatten (map
      (dirPath: map
        (fileName: "C /home/run/.local/share/fcitx5/rime/${dirPath}/${fileName} 0664 run users - ${rimeIceData}/${dirPath}/${fileName}")
        (rimeIceRegularEntriesInNested dirPath))
      rimeIceNestedDirEntries)
    ++ map
      (name: "C /home/run/.local/share/fcitx5/rime/${name} 0664 run users - ${iorestRimeDictSimplified}/${name}")
      iorestDictFiles
    ++ map
      (name: "C /home/run/.local/share/fcitx5/rime/opencc/${name} 0664 run users - ${openccData}/${name}")
      openccDataEntries;
}
