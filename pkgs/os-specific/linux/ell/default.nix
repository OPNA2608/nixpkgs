{ lib, stdenv
, fetchgit
, fetchpatch
, autoreconfHook
, pkg-config
, dbus
}:

stdenv.mkDerivation rec {
  pname = "ell";
  version = "0.51";

  outputs = [ "out" "dev" ];

  src = fetchgit {
    url = "https://git.kernel.org/pub/scm/libs/ell/ell.git";
    rev = version;
    sha256 = "sha256-UGc6msj+V3U7IzquD4+KDLWt1vUxdV2Qm9Y0FOmsqtc=";
  };

  patches = [
    # Fix breakage on musl
    # Remove with bump > 0.51
    (fetchpatch {
      url = "https://git.kernel.org/pub/scm/libs/ell/ell.git/patch/?id=ce7fcfe194f0abcb8f419f83276b16a4ab274032";
      sha256 = "sha256-7z2ObSGeSLyNqQ0JGa/qLK0I0pUiNB9F5FrEtY7XLNA=";
    })
  ];

  nativeBuildInputs = [
    pkg-config
    autoreconfHook
  ];

  checkInputs = [
    dbus
  ];

  enableParallelBuilding = true;

  doCheck = true;

  meta = with lib; {
    homepage = "https://git.kernel.org/pub/scm/libs/ell/ell.git";
    description = "Embedded Linux Library";
    longDescription = ''
      The Embedded Linux* Library (ELL) provides core, low-level functionality for system daemons. It typically has no dependencies other than the Linux kernel, C standard library, and libdl (for dynamic linking). While ELL is designed to be efficient and compact enough for use on embedded Linux platforms, it is not limited to resource-constrained systems.
    '';
    changelog = "https://git.kernel.org/pub/scm/libs/ell/ell.git/tree/ChangeLog?h=${version}";
    license = licenses.lgpl21Plus;
    platforms = platforms.linux;
    maintainers = with maintainers; [ mic92 dtzWill maxeaubrey ];
  };
}
