{ callPackage
, lib
}:

let
  common = opts: callPackage (import ./common.nix opts) { };
in
rec {
  # Broken
  hrodvitnir = common {
    codename = "hrodvitnir";
    isRelease = true;
    rev = "12432";
    sha256 = "sha256-8Dgekeu2j2QlfrhOyq4PilT450PoO31tu9Kh8W5d+lo=";
  };
  stable = hrodvitnir;
  # Working
  unstable = common {
    codename = "ichorescent";
    rev = "13037";
    sha256 = "sha256-AgaXQtGKo8Zajbe9hG4dOGywortF0XN/5fdl/MayyZ8=";
  };
}
