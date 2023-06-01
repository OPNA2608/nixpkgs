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

  meta = with lib; {
    description = "Notification and ringtone sound effects for Lomiri";
    homepage = "https://gitlab.com/ubports/development/core/lomiri-sounds";
    license = with licenses; [ cc-by-30 cc0 cc-by-sa-30 cc-by-40 ];
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.all;
  };
}
