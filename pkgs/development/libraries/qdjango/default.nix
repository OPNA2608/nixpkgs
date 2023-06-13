{ stdenv
, lib
, fetchFromGitHub
, testers
, doxygen
, qmake
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "qdjango";
  version = "unstable-2018-03-07";

  src = fetchFromGitHub {
    owner = "jlaine";
    repo = "qdjango";
    rev = "bda4755ece9d173a67b880e498027fcdc51598a8";
    hash = "sha256-5MfRfsIlv73VMvKMBCLviXFovyGH0On5ukLIEy7zwkk=";
  };

  outputs = [ "out" "dev" "doc" ];

  postPatch = ''
    # HTML docs depend on regular docs
    substituteInPlace qdjango.pro \
      --replace 'dist.depends = docs' 'htmldocs.depends = docs'
  '';

  qmakeFlags = [
    # Uses Qt testing infrascructure via QMake CONFIG testcase,
    # defaults to installing all testcase targets under Qt prefix
    # https://github.com/qt/qtbase/blob/29400a683f96867133b28299c0d0bd6bcf40df35/mkspecs/features/testcase.prf#L110-L120
    "CONFIG+=no_testcase_installs"

    # Qmake-generated pkg-config files default to Qt prefix
    "QMAKE_PKGCONFIG_PREFIX=${placeholder "out"}"
  ];

  nativeBuildInputs = [
    doxygen
    qmake
  ];

  dontWrapQtApps = true;

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  passthru.tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;

  meta = with lib; {
    description = "Qt-based C++ web framework";
    homepage = "https://github.com/jlaine/qdjango";
    license = licenses.lgpl21Plus;
    platforms = platforms.all;
    maintainers = with maintainers; [ OPNA2608 ];
    pkgConfigModules = [
      "qdjango-db"
      "qdjango-http"
    ];
  };
})
