{ stdenv
, lib
, fetchFromGitHub
, cmake
, libsForQt5
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "quickflux";
  version = "1.1-unstable-2020-11-10";

  src = fetchFromGitHub {
   owner = "benlau";
    repo = "quickflux";
    rev = "2a37acff0416c56cb349e5bc1b841b25ff1bb6f8";
    hash = "sha256-c0W3Qj8kY6hMcMy/v5xhwJF9+muZjotmJqhbjqQVab0=";
  };

  outputs = [
    "out"
    "dev"
  ];

  postPatch = ''
    # Don't hardcode static linking, let stdenv decide
    substituteInPlace CMakeLists.txt \
      --replace 'quickflux STATIC' 'quickflux' \
      --replace 'DESTINATION include' 'DESTINATION ''${CMAKE_INSTALL_INCLUDEDIR}'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = (with libsForQt5; [
    qtbase
    qtquickcontrols2
  ]);

  dontWrapQtApps = true;

  cmakeFlags = [
    (lib.cmakeBool "BUILD_SHARED_LIBS" (!stdenv.hostPlatform.isStatic))
  ];

  preFixup = ''
    # Has extra $out in includes list, breaks usage of module
    substituteInPlace $out/lib/cmake/QuickFlux/QuickFluxTargets.cmake \
      --replace "\''${_IMPORT_PREFIX}/include" '${placeholder "dev"}/include'
  '';

  meta = with lib; {
    description = "A Flux implementation for QML";
    homepage = "https://github.com/benlau/quickflux";
    license = licenses.asl20;
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.unix;
  };
})
