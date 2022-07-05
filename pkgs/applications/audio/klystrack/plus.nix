{ lib, stdenv, fetchFromGitHub
, SDL2, SDL2_image
, alsa-lib
, pkg-config
}:

let
  klystron = fetchFromGitHub {
    name = "klystron-plus-unstable-2022-07-05-src";
    owner = "LTVA1";
    repo = "klystron";
    rev = "a7b0ff63db3f2d657f59d78e9027be0245ac12a0";
    sha256 = "sha256-n68lsqaJNAxzZGsnRBdHRb0djD0ZHjkLiWIWotqVMag=";
  };
in
stdenv.mkDerivation rec {
  pname = "klystrack-plus";
  version = "unstable-2022-07-05";

  src = fetchFromGitHub {
    owner = "LTVA1";
    repo = "klystrack";
    rev = "b1367ec98e231544f53afe693323461b71a102f4";
    # submodule usage is broken, .gitmodule exists but the target directory doesn't...
    # fetchSubmodules = true;
    sha256 = "sha256-oKwoq1wd2INyhXYCrJi47Nt4EN2mVk8nUZsRzBrLEGg=";
  };

  prePatch = ''
    cp -r --no-preserve=all ${klystron} klystron
  '';

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
