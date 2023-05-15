{ stdenv
, lib
, fetchFromGitLab
, cmake
, cmake-extras
, deviceinfo
, libgbinder
, libglibutil
, pkg-config
, qtbase
, qtdeclarative
, qtfeedback
}:

stdenv.mkDerivation rec {
  pname = "hfd-service";
  version = "0.2.0";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-F1MLYcCYe2GAPNO3UuONM4/j9AnV+V2YgePBn2QY5zM=";
  };

  postPatch = ''
    substituteInPlace qt/feedback-plugin/CMakeLists.txt \
      --replace 'qt5/plugins' 'qt-${qtbase.version}/plugins'
    substituteInPlace init/CMakeLists.txt \
      --replace "\''${SYSTEMD_SYSTEM_DIR}" "$out/lib/systemd/system"
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
    qtdeclarative
  ];

  buildInputs = [
    cmake-extras
    deviceinfo
    libgbinder
    libglibutil
    qtbase
    qtfeedback
  ];

  cmakeFlags = [
    "-DENABLE_LIBHYBRIS=OFF"
  ];

  dontWrapQtApps = true;

  meta = with lib; {
    description = "DBus-activated service thatmanages human feedback devices such as LEDs and vibrators on mobile devices";
    homepage = "https://gitlab.com/ubports/development/core/hfd-service";
    license = licenses.lgpl3Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ OPNA2608 ];
  };
}
