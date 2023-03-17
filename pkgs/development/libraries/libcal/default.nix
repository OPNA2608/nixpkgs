# TODO
# - meta
{ stdenv
, lib
, fetchFromGitHub
, autoreconfHook
}:

stdenv.mkDerivation rec {
  pname = "libcal";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "maemo-leste";
    repo = "libcal";
    rev = version;
    hash = "sha256-ZaKmWTwGpUkhxzk9rznOYNMPip5YFNMQyjAAkmzYbBo=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
  ];
}
