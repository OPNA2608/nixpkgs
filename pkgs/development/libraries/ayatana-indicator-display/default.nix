{ stdenv
, lib
, fetchFromGitHub
, cmake
, cmake-extras
, cppcheck
, dbus
, geoclue2
, glib
, gtest
, intltool
, libayatana-common
, libgudev
, libqtdbusmock
, libqtdbustest
, lomiri-schemas
, pkg-config
, properties-cpp
, python3
, qtbase
, systemd
, wrapGAppsHook
, xsct
}:

let
  pythonEnv = python3.withPackages (ps: with ps; [
    python-dbusmock
  ]);
in
stdenv.mkDerivation rec {
  pname = "ayatana-indicator-display";
  version = "22.9.4";

  src = fetchFromGitHub {
    owner = "AyatanaIndicators";
    repo = "ayatana-indicator-display";
    rev = version;
    hash = "sha256-PU0BxhY4tSddxYdDH4r5MMcYXw//dLVSUxR2TecUqp4=";
  };

  postPatch = ''
    # Queries systemd user unit dir via pkg_get_variable, can't override prefix
    substituteInPlace data/CMakeLists.txt \
      --replace 'DESTINATION "''${SYSTEMD_USER_DIR}"' 'DESTINATION "${placeholder "out"}/lib/systemd/user"' \
      --replace '/etc' "\''${CMAKE_INSTALL_SYSCONFDIR}"

    # Must recursively search for schema, else success depends on what values comes first in GSETTINGS_SCHEMA_DIR
    substituteInPlace src/rotation-lock.cpp \
      --replace 'g_settings_schema_source_lookup(pSource, "com.lomiri.touch.system", FALSE)' 'g_settings_schema_source_lookup(pSource, "com.lomiri.touch.system", TRUE)' \
      --replace 'g_settings_schema_source_lookup(pSource, "org.ayatana.indicator.display", FALSE)' 'g_settings_schema_source_lookup(pSource, "org.ayatana.indicator.display", TRUE)'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    glib # for schema discovery
    intltool
    pkg-config
    wrapGAppsHook
  ];

  buildInputs = [
    cmake-extras
    geoclue2
    glib
    libayatana-common
    libgudev
    lomiri-schemas # for schema
    qtbase
    systemd
  ];

  dontWrapQtApps = true;

  nativeCheckInputs = [
    cppcheck
    dbus
    pythonEnv
    xsct
  ];

  checkInputs = [
    gtest
    libqtdbusmock
    libqtdbustest
    properties-cpp
  ];

  cmakeFlags = [
    "-DENABLE_LOMIRI_FEATURES=ON"
    "-DENABLE_TESTS=${lib.boolToString doCheck}"
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DGSETTINGS_COMPILE=ON"
  ];

  preFixup = ''
    # Uses g_settings_schema_source_get_default + g_settings_schema_source_lookup
    gappsWrapperArgs+=(
      --prefix GSETTINGS_SCHEMA_DIR : ${glib.makeSchemaPath "$out" "${pname}-${version}"}
      --prefix GSETTINGS_SCHEMA_DIR : ${glib.makeSchemaPath lomiri-schemas lomiri-schemas.name}
    )
  '';

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
}
