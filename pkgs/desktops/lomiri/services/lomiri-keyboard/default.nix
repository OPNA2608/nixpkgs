{
  stdenv,
  lib,
  fetchFromGitLab,
  unstableGitUpdater,
  anthy,
  glib,
  gsettings-qt,
  hunspell,
  libchewing,
  libpinyin,
  lomiri-ui-toolkit,
  maliit-framework,
  pkg-config,
  qmake,
  qtbase,
  qtdeclarative,
  qtmultimedia,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "lomiri-keyboard";
  version = "1.0.3-unstable-2026-05-11";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/lomiri-keyboard";
    rev = "6e45e12d866c63506dd584ba71219c3d457defea";
    hash = "sha256-UmUqEHQDMvfJQBhXXwSxYzKntPUUcAjsRmKtpr3FZaY=";
  };

  patches = [
    ./2000-plugins-Make-presage-opt-in.patch
  ];

  postPatch = ''
    substituteInPlace config.pri \
      --replace-fail '$${MALIIT_PLUGINS_DATA_DIR}' "$out/share/maliit/plugins"

    substituteInPlace src/plugin/plugin.pro \
      --replace-fail '$${MALIIT_PLUGINS_DIR}' "$out/lib/maliit/plugins"

    substituteInPlace \
      src/plugin/keyboardsettings.cpp \
      tests/unittests/ut_keyboardsettings/fake_qgsettings.cpp \
      --replace-fail 'QGSettings/QGSettings' 'QGSettings'

    # Release target sets -Wl,--as-needed, adding this unconditionally here should be fine
    cat <<EOF >>config.pri
      CONFIG += link_pkgconfig
      PKGCONFIG += gsettings-qt
    EOF

    # maliit-server expects this name
    substituteInPlace config.pri \
      --replace-fail \
        'LOMIRI_KEYBOARD_PLUGIN_TARGET = lomiri-keyboard-plugin' \
        'LOMIRI_KEYBOARD_PLUGIN_TARGET = maliit-keyboard-plugin'
    substituteInPlace \
      tests/unittests/ut_text/ut_text.pro \
      tests/unittests/ut_languagefeatures/ut_languagefeatures.pro \
      tests/unittests/ut_editor/ut_editor.pro \
      --replace-fail '-llomiri-keyboard-plugin' '-l$${LOMIRI_KEYBOARD_PLUGIN_TARGET}'

    substituteInPlace \
      config.pri \
      src/lib/logic/wordengine.cpp \
      po/po.pro \
      --replace-fail '/usr' "$out"

    # This just seems wrong, it should have flags for setting rpath flags but is set to just a path instead
    substituteInPlace \
      tests/unittests/ut_text/ut_text.pro \
      tests/unittests/ut_editor/ut_editor.pro \
      tests/unittests/ut_languagefeatures/ut_languagefeatures.pro \
      --replace-fail 'QMAKE_LFLAGS_RPATH' '# QMAKE_LFLAGS_RPATH'

    # LOMIRI_KEYBOARD_PLUGIN_LIB is shared, this variable is for static libraries
    substituteInPlace \
      tests/unittests/common/common.pro \
      tests/unittests/ut_wordengine/ut_wordengine.pro \
      tests/unittests/ut_word-candidates/ut_word-candidates.pro \
      --replace-fail 'PRE_TARGETDEPS += $${TOP_BUILDDIR}/$${LOMIRI_KEYBOARD_PLUGIN_LIB}' 'PRE_TARGETDEPS +='

    # line 6: LD_LIBRARY_PATH: not found
    substituteInPlace tests/unittests/common-check.pri \
      --replace-fail '$(LD_LIBRARY_PATH)' '$$(LD_LIBRARY_PATH)'

    # Don't install tests & their data, please
    find tests -name '*.pro' -exec sed -i -e 's/INSTALLS/#INSTALLS/g' -e 's/testcase/testcase no_testcase_installs/g' {} \;
  '';

  nativeBuildInputs = [
    glib # glib-compile-schemas
    pkg-config
    qmake
  ];

  buildInputs = [
    anthy
    gsettings-qt # missing pkg-config check
    hunspell
    libchewing
    libpinyin
    maliit-framework
    qtdeclarative
  ];

  propagatedBuildInputs = [
    lomiri-ui-toolkit
    qtmultimedia
  ];

  dontWrapQtApps = true;

  qmakeFlags =
    [
      "MALIIT_DEFAULT_PROFILE=lomiri"
      "CONFIG+=enable-hunspell"
      "CONFIG+=enable-pinyin"
    ]
    ++ lib.optionals (!finalAttrs.finalPackage.doCheck) [
      "CONFIG+=notests"
    ];

  postConfigure = ''
    make qmake_all
  '';

  doCheck = true;

  preCheck =
    let
      listToQtVar =
        list: suffix: lib.strings.concatMapStringsSep ":" (drv: "${lib.getBin drv}/${suffix}") list;
    in
    ''
      export QT_QPA_PLATFORM=minimal
      export QT_PLUGIN_PATH=${listToQtVar [ qtbase ] qtbase.qtPluginPrefix}
    '';

  postInstall = ''
    glib-compile-schemas --strict $out/share/glib-2.0/schemas
  '';

  passthru.updateScript = unstableGitUpdater { };

  meta = {
    description = "Ubuntu Touch keyboard as maliit plugin";
    longDescription = ''
      This is a C++ based Keyboard Plugin for Maliit, based on the Maliit Reference plugin, taking into account the
      special UI/UX requests of Ubuntu Phone.
    '';
    homepage = "https://gitlab.com/ubports/development/core/lomiri-keyboard";
    changelog = "https://gitlab.com/ubports/development/core/lomiri-keyboard/-/blob/${
      if (!builtins.isNull finalAttrs.src.tag) then finalAttrs.src.tag else finalAttrs.src.rev
    }/ChangeLog";
    license = lib.licenses.lgpl3Only;
    teams = [ lib.teams.lomiri ];
    platforms = lib.platforms.linux;
  };
})
