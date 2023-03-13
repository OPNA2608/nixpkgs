# TODO
# - tests (if possible)
# - meta
# - consider dropping in favour of maliit-keyboard instead? https://gitlab.com/ubports/development/core/lomiri-keyboard/-/issues/191
{ stdenv
, lib
, fetchFromGitLab
, anthy
, glib
, gsettings-qt
, hunspell
, libchewing
, libpinyin
, maliit-framework
, pkg-config
, presage
, qmake
, qtdeclarative
}:

stdenv.mkDerivation rec {
  pname = "lomiri-keyboard";
  version = "unstable-2023-03-05";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = "e395b2bb8a6859017318c3fdce8b8bb57dc68fa7";
    hash = "sha256-Y9MTHbFj74AAaTyfXfoGqUj4ytEDh1YfzZU+PYTVL00=";
  };

  postPatch = ''
    substituteInPlace src/plugin/plugin.pro config.pri \
      --replace '$${MALIIT_PLUGINS_DIR}' "$out/lib/maliit" \
      --replace '$${MALIIT_PLUGINS_DATA_DIR}' "$out/share/maliit/plugins"
    substituteInPlace po/po.pro \
      --replace '/usr' "$out"
  '';

  strictDeps = true;

  nativeBuildInputs = [
    glib # glib-compile-schemas
    maliit-framework # qmake specs
    pkg-config
    qmake
    qtdeclarative # qmake specs
  ];

  buildInputs = [
    anthy
    glib
    gsettings-qt
    hunspell
    libchewing
    libpinyin
    maliit-framework
    presage
    qtdeclarative
  ];

  dontWrapQtApps = true;

  qmakeFlags = [
    "MALIIT_DEFAULT_PROFILE=lomiri"
    "CONFIG+=enable-presage"
    "CONFIG+=enable-hunspell"
    "CONFIG+=enable-pinyin"
    "CONFIG+=nodoc"
    # Tests incompatible with our version of maliit-framework
    "CONFIG+=notests"
  ];

  postConfigure = ''
    make qmake_all
  '';

  postInstall = ''
    glib-compile-schemas $out/share/glib-2.0/schemas
  '';
}
