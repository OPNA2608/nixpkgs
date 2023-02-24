{ stdenv
, lib
, fetchFromGitHub
, cmake
, cmake-extras
, glib
, gobject-introspection
, gtest
, intltool
, lomiri-url-dispatcher
, pkg-config
, systemd
, vala
}:

stdenv.mkDerivation rec {
  pname = "libayatana-common";
  version = "0.9.8";

  src = fetchFromGitHub {
    owner = "AyatanaIndicators";
    repo = "libayatana-common";
    rev = version;
    hash = "sha256-5cHFjBQ3NgNaoprPrFytnrwBRL7gDG7QZLWomgGBJMg=";
  };

  postPatch = ''
    # Queries via pkg_get_variable, can't override prefix
    substituteInPlace data/CMakeLists.txt \
      --replace 'DESTINATION "''${SYSTEMD_USER_UNIT_DIR}"' 'DESTINATION "${placeholder "out"}/lib/systemd/user"'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    gobject-introspection
    intltool
    pkg-config
    vala
  ];

  buildInputs = [
    cmake-extras
    glib
    lomiri-url-dispatcher
    systemd
  ];

  checkInputs = [
    gtest
  ];

  cmakeFlags = [
    "-DENABLE_TESTS=${lib.boolToString doCheck}"
    "-DENABLE_LOMIRI_FEATURES=ON"
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DGSETTINGS_COMPILE=ON"
  ];

  # TODO
  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
}
