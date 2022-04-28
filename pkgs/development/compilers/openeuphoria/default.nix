{ stdenv
, lib
, fetchzip
, autoPatchelfHook
}:

let
  platFun = {
    x86_64-linux = "Linux-x64";
    i686-linux = "Linux-x86";
    x86_64-darwin = "OSX-x64";
  }.${stdenv.system};
  sha256 = {
    x86_64-linux = "0h73rfnrmsrl9dykh4lviwsxr83p78bzkfmvnvzr5dsay7k3l4m3";
    i686-linux = "07vpyhmpv5lrslc2lw4qxvybcb5fi5cf7rpmy91rsm5kcs602glc";
    x86_64-darwin = "1353pf39w82rj70radnakbs3qlz0gv3p41gn9hn2cmxa7pwvicq7";
  }.${stdenv.system};
in
stdenv.mkDerivation rec {
  pname = "openeuphoria";
  version = "4.1.0";
  commit = "57179171dbed";

  src = fetchzip {
    url = "https://github.com/OpenEuphoria/euphoria/releases/download/${version}/euphoria-${version}-${platFun}-${commit}.tar.gz";
    inherit sha256;
  };

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    substituteInPlace bin/eu.cfg \
      --replace "/usr/local/euphoria-${version}-${platFun}" "$out"

    mkdir $out
    cp -R * $out/

    runHook postInstall
  '';
}
