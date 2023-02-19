{ stdenv
, lib
, fetchFromGitLab
, cmake
, docbook-xsl-nons
, docbook_xml_dtd_45
, gettext
, glib
, glibcLocales
, withExamples ? true
, gtk3
, withDocumentation ? true
, gtk-doc
, pkg-config
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

  outputs = [
    "out"
    "dev"
  ] ++ lib.optionals withDocumentation [
    "doc"
  ];
  outputBin = "dev";

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
    gettext
    glib # glib-compile-resources
    pkg-config
  ] ++ lib.optionals withDocumentation [
    docbook-xsl-nons
    docbook_xml_dtd_45
    gtk-doc
  ];

  buildInputs = [
    glib
  ] ++ lib.optionals withExamples [
    gtk3
  ];

  # Tests need to be able to check locale
  LC_ALL = lib.optionalString doCheck "en_US.UTF-8";
  nativeCheckInputs = [
    glibcLocales
  ];

  makeFlags = [
    # ld: geonames-scan.o: undefined reference to symbol 'qsort@@GLIBC_2.2.5'
    "LD=${stdenv.cc.targetPrefix}cc"
  ];

  cmakeFlags = [
    "-DWANT_DOC=${lib.boolToString withDocumentation}"
    "-DWANT_DEMO=${lib.boolToString withExamples}"
    "-DWANT_TESTS=${lib.boolToString doCheck}"
  ];

  preInstall = lib.optionalString withDocumentation ''
    # gtkdoc-mkhtml generates images without write permissions, errors out during install
    chmod +w doc/reference/html/*
  '';

  #doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  doCheck = false;

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
