{ stdenv
, lib
, fetchFromGitLab
, cmake
, pkg-config
, gsettings-qt
, libqtdbustest
, libqtdbusmock
, libuuid
, lomiri-api
, lomiri-app-launch
, lomiri-url-dispatcher
, lttng-ust
, mir_1
, process-cpp
, qtbase
, qtdeclarative
, qtsensors
, valgrind
}:

stdenv.mkDerivation rec {
  pname = "qtmir";
  version = "unstable-2023-01-15";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/qtmir";
    rev = "c7670f8cf81a0535c13a82e9c041f6e933a17aa8";
    hash = "sha256-G5L1vhnfLeCoR4w7MhqiQUIbps2hhPdeKJV3kG+vCJI=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    gsettings-qt
    libqtdbustest
    libqtdbusmock
    libuuid
    lomiri-api
    lomiri-app-launch
    lomiri-url-dispatcher
    lttng-ust
    mir_1
    process-cpp
    qtbase
    qtdeclarative
    qtsensors
    valgrind
  ];

  dontWrapQtApps = true;
}
