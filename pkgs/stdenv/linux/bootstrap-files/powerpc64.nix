#
# Files came from this Hydra build:
#
#   nix-build ./pkgs/stdenv/linux/make-bootstrap-tools.nix -A build --option system powerpc64-linux
#
# Which used nixpkgs revision 4f7417acdd9215d14a717df6749467625d5694a4
# to instantiate:
#
#   /nix/store/1dcn3v18l4wyznbk56v4ff02ya51qykq-stdenv-bootstrap-tools.drv
#
# and then built:
#
#   /nix/store/cp9x1xk1f41ag5v85bq946nsj2bfrniz-stdenv-bootstrap-tools
#
{
  # Included for convenience, removed from the final PR
  # nix store add-path ./ppc64/busybox
  # nix hash to-sri --type sha256 $(nix-prefetch-url --executable file://$PWD/ppc64/busybox)
  busybox = import <nix/fetchurl.nix> {
    url = "http://tarballs.nixos.org/stdenv-linux/powerpc64/4f7417acdd9215d14a717df6749467625d5694a4/busybox";
    sha256 = "sha256-ZqPlBFaBPdeZQjy6cXWmBRM1ATBbxP/0tViN7jOJzAQ=";
    executable = true;
  };
  # Included for convenience, removed from the final PR
  # nix store add-file ./ppc64/bootstrap-tools.tar.xz
  # nix hash to-sri --type sha256 $(nix-prefetch-url file://$PWD/ppc64/busybox)
  bootstrapTools = import <nix/fetchurl.nix> {
    url = "http://tarballs.nixos.org/stdenv-linux/powerpc64/4f7417acdd9215d14a717df6749467625d5694a4/bootstrap-tools.tar.xz";
    sha256 = "sha256-djiKdEDU2blBVG+3UtMau+MoPrTXrsJt1FuTKweLomQ=";
  };
}
