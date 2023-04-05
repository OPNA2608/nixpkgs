# TODO
# - docs
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitLab
, boost
, cmake
, dbus
, dbus-cpp
, gettext
, glog
, json_c
, libapparmor
, net-cpp
, pkg-config
, process-cpp
, properties-cpp
, qtbase
, qtlocation
, trust-store
}:

stdenv.mkDerivation rec {
  pname = "location-service";
  version = "unstable-2023-03-28";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = "875cece91437779a064d8e22d48eb07561398939";
    hash = "sha256-4HoERC0gRu9PeXf7x0yaiBD9KPFSeKjAuFTH6Yo8eQg=";
  };

  postPatch = ''
    substituteInPlace qt/position/CMakeLists.txt \
      --replace '"''${CMAKE_INSTALL_LIBDIR}/qt5/plugins/position"' '"${placeholder "out"}/${qtbase.qtPluginPrefix}/position"'

    substituteInPlace data/CMakeLists.txt \
      --replace 'DESTINATION /etc' "DESTINATION $out/etc" \
      --replace 'DESTINATION /lib' "DESTINATION $out/lib" \
      --replace 'DESTINATION /usr' "DESTINATION $out"
    substituteInPlace data/lomiri-location-service-trust-stored.service.in \
      --replace '@CMAKE_INSTALL_FULL_BINDIR@/trust-stored-skeleton' '${trust-store}/bin/trust-stored-skeleton' \
      --replace '--local-agent MirAgent' '--local-agent TerminalAgent'
  '' + lib.optionalString (!doCheck) ''
    sed -i -e '/add_subdirectory(tests)/d' CMakeLists.txt
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    gettext
    pkg-config
  ];

  buildInputs = [
    boost
    dbus
    dbus-cpp
    glog
    json_c
    libapparmor
    net-cpp
    process-cpp
    properties-cpp
    qtbase
    qtlocation
    trust-store
  ];

  dontWrapQtApps = true;

  # TODO
  doCheck = false;
}
