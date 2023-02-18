{ stdenvNoCC
, lib
, fetchFromGitLab
, cmake
, dbus
, deviceinfo
, inotify-tools
, lomiri
, makeWrapper
, pkg-config
, systemd
}:

stdenvNoCC.mkDerivation rec {
  pname = "lomiri-session";
  version = "0.2";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-1ZpAn1tFtlXIfeejG0TnrJBRjf3tyz7CD+riWo+sd0s=";
  };

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace 'project(lomiri-session VERSION ${version})' 'project(lomiri-session VERSION ${version} LANGUAGES NONE)'
    substituteInPlace desktop/dm-lomiri-session \
      --replace '/usr/lib' "$out/lib"
    substituteInPlace systemd/lomiri.service \
      --replace '/usr/bin/lomiri-session' "$out/bin/lomiri-session" \
      --replace '/usr/bin/dbus-update-activation-environment' '${lib.getBin dbus}/bin/dbus-update-activation-environment'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    makeWrapper
    pkg-config
  ];

  buildInputs = [
    deviceinfo
    dbus
    inotify-tools
    # Wants=ayatana-indicators.target
    # libayatana-common
    lomiri
    systemd
  ];

  cmakeFlags = [
    # Requires lomiri-system-compositor -> not ported to Mir 2.x yet
    "-DENABLE_TOUCH_SESSION=OFF"
  ];

  postInstall = ''
    wrapProgram $out/bin/lomiri-session \
      --prefix PATH : ${lib.makeBinPath [ deviceinfo inotify-tools lomiri ]}
  '';

  passthru.providedSessions = [
    "lomiri"
    # "lomiri-touch"
  ];
}
