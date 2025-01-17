{
  lib,
  aiohttp,
  beautifulsoup4,
  buildPythonPackage,
  cryptography,
  fetchFromGitHub,
  flit-core,
  lxml,
  pyjwt,
  pythonOlder,
}:

buildPythonPackage rec {
  pname = "skodaconnect";
  version = "1.3.11";
  pyproject = true;

  disabled = pythonOlder "3.11";

  src = fetchFromGitHub {
    owner = "lendy007";
    repo = "skodaconnect";
    tag = version;
    hash = "sha256-Cy2sXj8+t8lIqrKmI9Aa7tNEIvRArynU/02ajJ+tYHg=";
  };

  nativeBuildInputs = [ flit-core ];

  propagatedBuildInputs = [
    aiohttp
    beautifulsoup4
    cryptography
    lxml
    pyjwt
  ];

  # Project has no tests
  doCheck = false;

  pythonImportsCheck = [ "skodaconnect" ];

  meta = with lib; {
    description = "Python module to communicate with Skoda Connect";
    homepage = "https://github.com/lendy007/skodaconnect";
    changelog = "https://github.com/lendy007/skodaconnect/releases/tag/${version}";
    license = with licenses; [ asl20 ];
    maintainers = with maintainers; [ fab ];
  };
}
