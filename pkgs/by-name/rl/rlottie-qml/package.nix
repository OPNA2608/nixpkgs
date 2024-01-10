{ stdenv
, lib
, fetchFromGitLab
, cmake
, libsForQt5
, rlottie
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "rlottie-qml";
  version = "unstable-2021-05-03";

  src = fetchFromGitLab {
    owner = "mymike00";
    repo = "rlottie-qml";
    rev = "f9506889a284039888c7a43db37e155bb7b30c40";
    hash = "sha256-e2/4e1GGFfJMwShy6qgnUVVRxjV4WfjQwcqs09RK194=";
  };

  outputs = [
    "out"
    "dev"
  ];

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace 'QT_IMPORTS_DIR "/lib/''${ARCH_TRIPLET}"' 'QT_IMPORTS_DIR "''${CMAKE_INSTALL_PREFIX}/${libsForQt5.qtbase.qtQmlPrefix}"' \
      --replace "\''${QT_IMPORTS_DIR}/\''${PLUGIN}" "\''${QT_IMPORTS_DIR}" \
      --replace 'QuaZip REQUIRED' 'QuaZip-Qt5 REQUIRED' \
      --replace "\''${QUAZIP_LIBRARIES}" 'QuaZip::QuaZip'

    substituteInPlace cmake/rLottieQmlConfig.cmake.in \
      --replace '# find_dependency(QuaZip REQUIRED)' 'find_dependency(QuaZip-Qt5 REQUIRED)'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    rlottie
  ] ++ (with libsForQt5; [
    qtbase
    qtdeclarative
    qtmultimedia
    quazip
  ]);

  dontWrapQtApps = true;
})
