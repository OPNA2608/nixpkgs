{ stdenvNoCC
, lib
, fetchFromGitLab
, fetchpatch
, cmake
, dbus
, deviceinfo
, inotify-tools
, lomiri
, makeWrapper
, pkg-config
, runtimeShell
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

  patches = [
    # Removes broken first-time wizard check
    (fetchpatch {
      url = "https://salsa.debian.org/ubports-team/lomiri-session/-/raw/9522c7b23ab53aa270b26ed60b7b87a95995f453/debian/patches/0001_desktop-dm-lomiri-session-Drop-old-wizard-has-run-ch.patch";
      hash = "sha256-AIwgztFOGwG2zUsaUen/Z3Mes9m7VgbvNKWp/qYp4g4=";
    })
    # Fix quoting on ps check
    (fetchpatch {
      url = "https://salsa.debian.org/ubports-team/lomiri-session/-/raw/58b8e4e8b8316cdacfde942b8288f792beb65cd5/debian/patches/0002_lomiri-session-Put-evaluation-of-ps-call-in-quotes.patch";
      hash = "sha256-SwTIsB0zLRJupkikeVNrXSduaCNke/XWCWBgaNUkCtU=";
    })
    # Properly gate of UBtouch-specific code
    # Otherwise session won't launch, errors out on a removed Mir setting
    (fetchpatch {
      url = "https://salsa.debian.org/ubports-team/lomiri-session/-/raw/58b8e4e8b8316cdacfde942b8288f792beb65cd5/debian/patches/0003_lomiri-session-Properly-differentiate-between-Ubuntu.patch";
      hash = "sha256-eFiagFEpH43WpVGA6xkI1IiQ99HHizonhXYg1wYAhwU=";
    })
    # Remove outdated Before & Wants targets
    (fetchpatch {
      url = "https://salsa.debian.org/ubports-team/lomiri-session/-/raw/d2eb6ca69fca00baf02003b789edcfdfad4f5e61/debian/patches/0005_systemd-lomiri.service-Drop-Before-and-Wants-for-ind.patch";
      hash = "sha256-vGFvcCjbwcuLrAUIsL5y/QmoOR5i0560LNv01ZT9OOg=";
    })
  ];

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
    lomiri
    systemd
  ];

  cmakeFlags = [
    # Requires lomiri-system-compositor -> not ported to Mir 2.x yet
    "-DENABLE_TOUCH_SESSION=OFF"
  ];

  postInstall = ''
    substituteInPlace $out/bin/lomiri-session \
      --replace '/bin/bash' '${runtimeShell}'
    wrapProgram $out/bin/lomiri-session \
      --prefix PATH : ${lib.makeBinPath [ deviceinfo inotify-tools lomiri ]}
  '';

  passthru.providedSessions = [
    "lomiri"
    # "lomiri-touch"
  ];
}
