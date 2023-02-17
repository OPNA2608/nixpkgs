{ stdenvNoCC
, lib
, fetchFromGitLab
, cmake
, qtbase
}:

stdenvNoCC.mkDerivation rec {
  pname = "cmake-extras";
  version = "unstable-2022-11-21";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = "99aab4514ee182cb7a94821b4b51e4d8cb9a82ef";
    hash = "sha256-axj5QxgDrHy0HiZkfrbm22hVvSCKkWFoQC8MdQMm9tg=";
  };

  postPatch = ''
    # We have nothing to build here, no need to depend on a C compiler
    substituteInPlace CMakeLists.txt \
      --replace 'project(cmake-extras)' 'project(cmake-extras NONE)'

    # Qt's wrappers expect this to contain the Qt version
    substituteInPlace src/QmlPlugins/QmlPluginsConfig.cmake \
      --replace 'qt5/qml' 'qt-${qtbase.version}/qml'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
  ];

  meta = with lib; {
    description = "A collection of add-ons for the CMake build tool";
    homepage = "https://gitlab.com/ubports/development/core/cmake-extras/";
    license = licenses.gpl3Only;
    platforms = platforms.all;
    maintainers = with maintainers; [ OPNA2608 ];
  };
}
