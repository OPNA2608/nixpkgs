{ stdenv
, lib
, fetchFromGitHub
, doxygen
, qmake
, qtbase
}:

stdenv.mkDerivation rec {
  pname = "qdjango";
  version = "unstable-2018-03-07";

  src = fetchFromGitHub {
    owner = "jlaine";
    repo = "qdjango";
    rev = "bda4755ece9d173a67b880e498027fcdc51598a8";
    hash = "sha256-5MfRfsIlv73VMvKMBCLviXFovyGH0On5ukLIEy7zwkk=";
  };

  postPatch = ''
    # HTML docs depend on regular docs
    substituteInPlace qdjango.pro \
      --replace 'dist.depends = docs' 'htmldocs.depends = docs'
  '';

  postConfigure = ''
    # This project provides Qt Tests (testlib, testcase) and wants to install them to qtbase's directory.
    # This behaviour is caused by the QMake CONFIGs these tests are using to be registered as tests.
    # Force recursive Makefile creation, manually patch qtbase paths out of the generated Makefiles.
    make qmake_all
    for makeFile in $(find tests -name Makefile); do
      substituteInPlace $makeFile \
        --replace '$(INSTALL_ROOT)${qtbase.dev}/tests/' '$(INSTALL_ROOT)${placeholder "out"}/tests/'
    done
  '';

  nativeBuildInputs = [
    doxygen
    qmake
  ];

  dontWrapQtApps = true;

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  postInstall = ''
    # Don't install the test binaries
    rm -r $out/tests
  '';

  meta = with lib; {
    description = "Qt-based C++ web framework";
    homepage = "https://github.com/jlaine/qdjango";
    license = licenses.lgpl21Plus;
    platforms = platforms.all;
    maintainers = with maintainers; [ OPNA2608 ];
  };
}
