{ lib
, stdenv
, fetchFromGitHub
, cmake
, ninja
, wrapGAppsHook
, makeWrapper
, wxGTK
, Cocoa
, gitUpdater
}:

stdenv.mkDerivation rec {
  pname = "treesheets";
  version = "7861249636";

  src = fetchFromGitHub {
    owner = "aardappel";
    repo = "treesheets";
    rev = "refs/tags/${version}";
    hash = "sha256-FOeRfNPX1ER1ZMUWy+4b67XfrATPPZntfhywjaGgDpo=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    wrapGAppsHook
    makeWrapper
  ];

  buildInputs = [
    wxGTK
  ] ++ lib.optionals stdenv.isDarwin [
    Cocoa
  ];

  env.NIX_CFLAGS_COMPILE = "-DPACKAGE_VERSION=\"${version}\"";

  postInstall = lib.optionalString stdenv.isDarwin ''
    shopt -s extglob
    mkdir -p $out/{share/treesheets,bin}
    mv $out/!(share) $out/share/treesheets
    makeWrapper $out/{share/treesheets,bin}/treesheets \
      --chdir $out/share/treesheets
  '';

  passthru = {
    updateScript = gitUpdater { };
  };

  meta = with lib; {
    description = "Free Form Data Organizer";

    longDescription = ''
      The ultimate replacement for spreadsheets, mind mappers, outliners,
      PIMs, text editors and small databases.

      Suitable for any kind of data organization, such as Todo lists,
      calendars, project management, brainstorming, organizing ideas,
      planning, requirements gathering, presentation of information, etc.
    '';

    homepage = "https://strlen.com/treesheets/";
    maintainers = with maintainers; [ obadz avery ];
    platforms = platforms.unix;
    license = licenses.zlib;
  };
}
