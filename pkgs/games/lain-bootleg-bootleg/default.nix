{ stdenv
, lib
, fetchFromGitHub
, fetchpatch
, requireFile
, cmake
, pkg-config
, python3
, makeWrapper
, mpv
, glew
, glfw
, libX11
, CoreAudio
, AudioToolbox
}:

let
  reqFileMsg = name: ''
    This nix expression requires that ${name} is already part of the store.
    Find the file on your Serial Experiments Lain Bootleg CD-ROM and
    add it to the nix store with:
      nix-store --add-fixed sha256 /path/to/your/${name}
  '';
  win-dat = requireFile rec {
    name = "lain_win.dat";
    message = reqFileMsg name;
    sha256 = "02g1l60bki0y8hrpz6p2dzi6gzaq19f5a75s34d1yj7pa6va0j78";
  };
  mov-dat = requireFile rec {
    name = "lain_mov.dat";
    message = reqFileMsg name;
    sha256 = "1r3380gd6xfmixfb0mls1pbpgajj2idk9pc42i9yk7qv4fhlpis7";
  };
  win-exe = requireFile rec {
    name = "lain_win.exe";
    message = reqFileMsg name;
    sha256 = "094rsb7ss1cmi7ziypfnx2hjj8qvn3q22ji6d13q3j3jd18pga1a";
  };
in
stdenv.mkDerivation rec {
  pname = "lain-bootleg-bootleg";
  version = "unstable-2022-01-02";

  src = fetchFromGitHub {
    owner = "ad044";
    repo = "lain-bootleg-bootleg";
    rev = "07ecd969209f85cae3a79bbb090a096f567e2662";
    sha256 = "1if1qwzzycg58fikxh24rm4c17lp1sc1anyvj2nma1mv801pz68r";
  };

  postPatch = ''
    # OpenGL4.3 function despite only requesting OpenGL3.3
    # Never available on Darwin & only produces debug output
    # Waiting for upstream to find ideal fix
    sed -i -e '/glDebugMessageCallback/d' src/window.c
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
    (python3.withPackages (ps: with ps; [
      numpy
      opencv4
      pillow
      pefile
    ]))
    makeWrapper
  ];

  buildInputs = [
    mpv
    glew
    glfw
  ] ++ lib.optionals stdenv.hostPlatform.isLinux [
    libX11
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [
    CoreAudio
    AudioToolbox
  ];

  cmakeFlags = [
    "-DSYSTEM_GLEW=ON"
    "-DSYSTEM_GLFW=ON"
    "-DOpenGL_GL_PREFERENCE=GLVND"
  ];

  preConfigure = ''
    pushd scripts
    mkdir binaries
    for file in ${win-dat} ${mov-dat} ${win-exe}; do
      ln -s $file ./binaries/$(basename $file | cut -d'-' -f2)
    done
    python3 ./make_game_assets.py
    popd
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/lain-bootleg-bootleg
    mv res $out/share/lain-bootleg-bootleg/
    install -Dm755 {.,$out/bin}/lain-bootleg-bootleg
    wrapProgram $out/bin/lain-bootleg-bootleg \
      --run "cd $out/share/lain-bootleg-bootleg"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Reverse engineering and remaking Lain Bootleg";
    homepage = "https://laingame.net/bootleg/";
    license = licenses.unfree;
    platforms = platforms.all;
    maintainers = with maintainers; [ OPNA2608 ];
  };
}
