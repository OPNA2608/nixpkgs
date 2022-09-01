{ stdenvNoCC
, lib
, fetchFromGitLab
, jdk
, openssl
, wget
, makeWrapper
, openal
, dialogApp ? "none"
, gnome
, libsForQt5
}:

assert lib.asserts.assertOneOf "dialogApp" dialogApp [ "zenity" "kdialog" "none" ];

let
  runtimeBins = [
    jdk
    openssl
    wget
  ] ++ lib.optionals (dialogApp == "zenity") [
    gnome.zenity
  ] ++ lib.optionals (dialogApp == "kdialog") [
    libsForQt5.kdialog
  ];
  runtimeLibs = openal.buildInputs;
in
stdenvNoCC.mkDerivation rec {
  pname = "pokemmo-installer";
  version = "1.4.8";

  src = fetchFromGitLab {
    owner = "coringao";
    repo = "pokemmo-installer";
    rev = version;
    sha256 = "sha256-uSbnXBpkeGM9X6DU7AikT7hG/emu67PXuGdm6xfB8To=";
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  buildInputs = runtimeBins;# ++ runtimeLibs;

  installFlags = [
    "PREFIX=${placeholder "out"}"
    "BINDIR=${placeholder "out"}/bin"
  ];

  postInstall = ''
    wrapProgram $out/bin/pokemmo-installer \
      --prefix PATH : ${lib.makeBinPath runtimeBins} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath (lib.lists.forEach runtimeLibs (x: x.out))}
  '';
}
