{
  stdenv,
  lib,
  fetchFromGitHub,
  gnat,
  gprbuild,
}:

stdenv.mkDerivation rec {
  pname = "powerjoular";
  version = "1.0.4";

  src = fetchFromGitHub {
    owner = "joular";
    repo = pname;
    rev = version;
    hash = "sha256-zcG/R8isL7WcwsIFovnRKZ5DCtZu4vJWOximFY9ARuE=";
  };

  nativeBuildInputs = [
    gnat
    gprbuild
  ];

  buildPhase = ''
    runHook preBuild
    gprbuild
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp obj/powerjoular $out/bin
    runHook postInstall
  '';

  meta = with lib; {
    description = "CLI software to monitor the power consumption of software and hardware components";
    homepage = "https://github.com/joular/powerjoular";
    maintainers = [ maintainers.julienmalka ];
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
