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
    sha256 = "124dlfydyyhhv7r5s2610k6yjibvvrljxw41w1bayvjgzzsalnr5";
  };
  stable = hrodvitnir;
  # Working
  unstable = common {
    codename = "ichorescent";
    rev = "12996";
    sha256 = "EDovtpZR/M/p88+sX62nptROzcbyDU/sLoUY57JbbWw=";
  };
}
