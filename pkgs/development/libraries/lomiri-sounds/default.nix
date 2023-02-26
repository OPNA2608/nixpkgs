{ stdenvNoCC
, lib
, fetchFromGitLab
, cmake
}:

stdenvNoCC.mkDerivation rec {
  pname = "lomiri-sounds";
  version = "22.02";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-t9JYxrJ5ICslxidHmbD1wa6n7XZMf2a+PgMLcwgsDvU=";
  };

  postPatch = ''
    # Doesn't need a compiler, only installs data
    substituteInPlace CMakeLists.txt \
      --replace 'project (lomiri-sounds)' 'project (lomiri-sounds LANGUAGES NONE)'
  '';

  nativeBuildInputs = [
    cmake
  ];
}
