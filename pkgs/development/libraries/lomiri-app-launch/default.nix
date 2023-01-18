{ stdenv
, lib
, fetchFromGitLab
, cmake
, cmake-extras
, pkg-config
, gobject-introspection
, apparmor-bin-utils
, mir_1
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
  version = "0.1.3";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/lomiri-app-launch";
    rev = version;
    hash = "sha256-HI56LRXblZj6YWpjibTDOBez2RZJGNMske4N65nGfY0=";
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
    mir_1
    properties-cpp
    libxkbcommon
    zeitgeist
  ];

  cmakeFlags = [
    "-DLOMIRI_APP_LAUNCH_ARCH=${stdenv.hostPlatform.config}"
  ];
}
