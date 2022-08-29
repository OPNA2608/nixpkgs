#
# Files came from this Hydra build:
#
#   nix-build ./pkgs/stdenv/linux/make-bootstrap-tools-cross.nix -A powerpc64.build
#
# Which used nixpkgs revision fb66cf2d50c5bb374e8fdbfb4f3f888bbc33e24a
# to instantiate:
#
#   /nix/store/49lfdfr41zg5sbk3d6q645krvcyfnilj-stdenv-bootstrap-tools-powerpc64-unknown-linux-gnuabielfv2.drv
#
# and then built:
#
#   /nix/store/8ldnj57601cqlj36vgw6si81l009mda5-stdenv-bootstrap-tools-powerpc64-unknown-linux-gnuabielfv2
#
{
  # Included for convenience, removed from the final PR
  # nix store add-path ./ppc64/busybox
  # nix hash to-sri --type sha256 $(nix-prefetch-url --executable file://$PWD/ppc64/busybox)
  busybox = import <nix/fetchurl.nix> {
    url = "http://tarballs.nixos.org/stdenv-linux/powerpc64/fb66cf2d50c5bb374e8fdbfb4f3f888bbc33e24a/busybox";
    sha256 = "sha256-B64XaMCnHsWASsadSQns9vMFc4Lh4+eQovBq7nh17Y8=";
    executable = true;
  };
  # Included for convenience, removed from the final PR
  # nix store add-file ./ppc64/bootstrap-tools.tar.xz
  # nix hash to-sri --type sha256 $(nix-prefetch-url file://$PWD/ppc64/busybox)
  bootstrapTools = import <nix/fetchurl.nix> {
    url = "http://tarballs.nixos.org/stdenv-linux/powerpc64/fb66cf2d50c5bb374e8fdbfb4f3f888bbc33e24a/bootstrap-tools.tar.xz";
    sha256 = "sha256-kR1r5a+s8VeccaFlqqNOqMyWDaGlWqHdR+bQz9yO+uM=";
  };
}
