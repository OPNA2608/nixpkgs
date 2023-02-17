{ stdenv
, lib
, fetchFromGitLab
, cmake
, cmake-extras
, pkg-config
, gobject-introspection
, apparmor-bin-utils
, glib
, json-glib
, lomiri-click
, zeitgeist
, dbus
, dbus-test-runner
, lttng-ust
, curl
, lomiri-api
, gtest
, libxkbcommon
, properties-cpp
}:

stdenv.mkDerivation rec {
  pname = "lomiri-app-launch";
  version = "0.1.4";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/lomiri-app-launch";
    rev = version;
    hash = "sha256-G1bzAB9A8E6eTsL39RVWO9MlgXxXq6OHzHYyRJyyYa8=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    cmake-extras
    curl
    dbus
    dbus-test-runner
    gobject-introspection
    gtest
    json-glib
    lomiri-api
    lomiri-click
    lttng-ust
    properties-cpp
    libxkbcommon
    zeitgeist
  ];

  cmakeFlags = [
    "-DENABLE_MIRCLIENT=OFF"
    "-DLOMIRI_APP_LAUNCH_ARCH=${stdenv.hostPlatform.config}"
  ];
}
