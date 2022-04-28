{ callPackage
, lib
}:

let
  common = opts: callPackage (import ./common.nix opts) { };
in
rec {
  hrodvitnir = common {
    codename = "hrodvitnir";
    isRelease = true;
    rev = "12432";
    sha256 = "124dlfydyyhhv7r5s2610k6yjibvvrljxw41w1bayvjgzzsalnr5";
  };
  unstable = common {
    codename = "ichorescent";
    rev = "12937";
    sha256 = "11rhvgf171p1zbanf3d2v5mjk5d115lwpi6wvckn7yc7q159ygqw";
  };
}
