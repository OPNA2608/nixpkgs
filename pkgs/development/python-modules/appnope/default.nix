{ lib
, buildPythonPackage
, fetchFromGitHub
, pytestCheckHook
}:

buildPythonPackage rec {
  pname = "appnope";
  version = "0.1.3";

  src = fetchFromGitHub {
    owner = "minrk";
    repo = "appnope";
    rev = version;
    sha256 = "sha256-JYzNOPD1ofOrtZK5TTKxbF1ausmczsltR7F1Vwss8Sw=";
  };

  checkInputs = [
    pytestCheckHook
  ];

  meta = with lib; {
    description = "Disable App Nap on macOS";
    homepage = "https://github.com/minrk/appnope";
    license = licenses.bsd3;
  };
}
