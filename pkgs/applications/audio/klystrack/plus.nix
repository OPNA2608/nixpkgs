{ lib, stdenv, fetchFromGitHub
, SDL2, SDL2_image
, alsa-lib
, pkg-config
}:

stdenv.mkDerivation rec {
  pname = "klystrack-plus";
  version = "unstable-2022-07-05";

  src = fetchFromGitHub {
    owner = "LTVA1";
    repo = "klystrack";
    rev = "e8eb67a6a4dd7a6be74f13203eb43ed2a9f64de6";
    fetchSubmodules = true;
    sha256 = "sha256-/HyaWZWHeetbU/Scw9VX7E1yQzhoeOKziVQREZwzTgQ=";
  };

  postPatch = ''
    # replace impure build dates
    for file in {,klystron/}Makefile; do
      substituteInPlace $file \
        --replace '$(Q)date' '$(Q)date -ud "@''${SOURCE_DATE_EPOCH}"'
    done
  '';

  buildInputs = [
    SDL2 SDL2_image
  ] ++ lib.optional stdenv.hostPlatform.isLinux [
    alsa-lib
  ];
  nativeBuildInputs = [ pkg-config ] ++ lib.optional stdenv.hostPlatform.isLinux [
    alsa-lib.dev
  ];

  enableParallelBuilding = true;

  # Workaround build failure on -fno-common toolchains:
  #   ld: libengine_gui.a(gui_menu.o):(.bss+0x0): multiple definition of
  #     `menu_t'; objs.release/action.o:(.bss+0x20): first defined here
  # TODO: remove it for 1.7.7+ release as it was fixed upstream.
  NIX_CFLAGS_COMPILE = "-fcommon";

  buildFlags = [ "PREFIX=${placeholder "out"}" "CFG=release" ];

  installPhase = ''
    install -Dm755 bin.release/klystrack $out/bin/klystrack

    mkdir -p $out/lib/klystrack
    cp -R res $out/lib/klystrack
    cp -R key $out/lib/klystrack

    install -DT icon/256x256.png $out/share/icons/hicolor/256x256/apps/klystrack.png
    mkdir -p $out/share/applications
    substitute linux/klystrack.desktop $out/share/applications/klystrack.desktop \
      --replace "klystrack %f" "$out/bin/klystrack %f"
  '';

  meta = with lib; {
    description = "A fork of a chiptune tracker";
    homepage = "https://github.com/LTVA1/klystrack";
    license = licenses.mit;
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.linux;
  };
}
