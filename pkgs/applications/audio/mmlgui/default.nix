{ stdenv
, lib
, fetchFromGitHub
, unstableGitUpdater
, pkgconf
, glfw
, libvgm
, libX11
, libXau
, libXdmcp
, Carbon
, Cocoa
, cppunit
}:

let
  libvgmMegaDrive = libvgm.override {
    withAllEmulators = false;
    emulators = [
      "_PRESET_SMD"
    ];
  };
in
stdenv.mkDerivation rec {
  pname = "mmlgui";
  version = "2022-02-05";

  src = fetchFromGitHub {
    owner = "superctr";
    repo = "mmlgui";
    rev = "66010f7396d24697d6e683bec616152bcc90156d";
    fetchSubmodules = true;
    sha256 = "123js5d1hvpyjyh2prjg3rnbxaxr7a8is2anra7srihg3z5kgpr8";
  };

  postPatch = ''
    # Actually wants pkgconf, but expects a pkg-config->pkgconf symlink
    for mkfile in {imgui,libvgm}.mak; do
      substituteInPlace $mkfile \
        --replace 'pkg-config' 'pkgconf'
    done
    substituteInPlace Makefile \
      --replace 'all: $(MMLGUI_BIN) test' 'all: $(MMLGUI_BIN)'
  '';

  nativeBuildInputs = [
    pkgconf
  ];

  buildInputs = [
    glfw
    libvgmMegaDrive
  ] ++ lib.optionals stdenv.hostPlatform.isLinux [
    libX11
    libXau
    libXdmcp
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [
    Carbon
    Cocoa
  ];

  checkInputs = [
    cppunit
  ];

  makeFlags = [
    "RELEASE=1"
  ];

  enableParallelBuilding = true;

  doCheck = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 {,$out/}bin/mmlgui
    mkdir -p $out/share/ctrmml
    mv ctrmml/sample $out/share/ctrmml/

    runHook postInstall
  '';

  passthru.updateScript = unstableGitUpdater {
    url = "https://github.com/superctr/mmlgui.git";
  };

  meta = with lib; {
    homepage = "https://github.com/superctr/mmlgui";
    description = "MML (Music Macro Language) editor and compiler GUI, powered by the ctrmml framework";
    license = licenses.gpl2Only;
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.all;
  };
}
