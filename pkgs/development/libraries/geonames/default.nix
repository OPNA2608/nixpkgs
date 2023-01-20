{ stdenv
, lib
, fetchFromGitLab
, cmake
, docbook-xsl-nons
, docbook_xml_dtd_45
, gettext
, gtk-doc
, pkg-config
, glib
, glibcLocales
, withExamples ? true
, gtk3
}:

stdenv.mkDerivation rec {
  pname = "geonames";
  version = "0.3.0";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-Mo7Khj2pgdJ9kT3npFXnh1WTSsY/B1egWTccbAXFNY8=";
  };

  postPatch = ''
    patchShebangs src/generate-locales.sh tests/setup-test-env.sh

    substituteInPlace doc/reference/CMakeLists.txt \
      --replace "\''${CMAKE_INSTALL_DATADIR}/gtk-doc/html/\''${PROJECT_NAME}" "\''${CMAKE_INSTALL_DOCDIR}"
    substituteInPlace demo/CMakeLists.txt \
      --replace 'RUNTIME DESTINATION bin' 'RUNTIME DESTINATION ''${CMAKE_INSTALL_BINDIR}'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    docbook-xsl-nons
    docbook_xml_dtd_45
    gettext
    pkg-config
    gtk-doc
    glib # glib-compile-resources
  ];

  buildInputs = [
    glib
  ] ++ lib.optionals withExamples [
    gtk3
  ];

  # Tests need to be able to check locale
  LC_ALL = lib.optionalString doCheck "en_US.UTF-8";
  checkInputs = [
    glibcLocales
  ];

  makeFlags = [
    # ld: geonames-scan.o: undefined reference to symbol 'qsort@@GLIBC_2.2.5'
    "LD=${stdenv.cc.targetPrefix}cc"
  ];

  cmakeFlags = [
    "-DWANT_DOC=ON"
    "-DWANT_DEMO=${if withExamples then "ON" else "OFF"}"
    "-DWANT_TESTS=${if doCheck then "ON" else "OFF"}"
  ];

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  outputs = [ "out" "dev" "doc" ];
  outputBin = "dev";

  meta = with lib; {
    description = "Parse and query the geonames database dump";
    homepage = "https://gitlab.com/ubports/development/core/geonames";
    license = licenses.gpl3Only;
    platforms = platforms.all;
    # https://gitlab.com/ubports/development/core/geonames/-/issues/1
    broken = !stdenv.buildPlatform.canExecute stdenv.hostPlatform;
    maintainers = with maintainers; [ OPNA2608 ];
  };
}
