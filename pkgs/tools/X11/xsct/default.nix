{ stdenv
, lib
, fetchFromGitHub
, libX11
, libXrandr
}:

stdenv.mkDerivation rec {
  pname = "xsct";
  version = "1.9";

  src = fetchFromGitHub {
    owner = "faf0";
    repo = "sct";
    rev = version;
    hash = "sha256-jsdTFRvrii43eTqk4PfCyjoLYAKguDBXY5SQ1sSSEuo=";
  };

  buildInputs = [
    libX11
    libXrandr
  ];

  makeFlags = [
    "PREFIX=${placeholder "out"}"
  ];

  meta = with lib; {
    description = "Set color temperature of screen";
    homepage = "https://github.com/faf0/sct";
    license = licenses.unlicense;
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = with platforms; linux ++ freebsd ++ openbsd;
  };
}
