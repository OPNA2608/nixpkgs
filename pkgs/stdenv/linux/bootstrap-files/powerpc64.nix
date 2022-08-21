#
# Files came from this Hydra build:
#
#   nix-build ./pkgs/stdenv/linux/make-bootstrap-tools-cross.nix -A powerpc64.build
#
# Which used nixpkgs revision ec90f8ea7355f843bd450cb5f8e9c7a693511e38
# to instantiate:
#
#   /nix/store/hswspikcg0fjsqn7lk9rgzac9jv9gfjb-stdenv-bootstrap-tools-powerpc64-unknown-linux-gnu.drv
#
# and then built:
#
#   /nix/store/17591m4m7dn771vwljbsa3ac79ayfvf6-stdenv-bootstrap-tools-powerpc64-unknown-linux-gnu
#
{
  # Included for convenience, removed from the final PR
  # nix store add-path ./ppc64/busybox
  busybox = import <nix/fetchurl.nix> {
    url = "http://tarballs.nixos.org/stdenv-linux/powerpc64/ec90f8ea7355f843bd450cb5f8e9c7a693511e38/busybox";
    sha256 = "sha256-4yYRzUCMnZit+B7n9J1j+OnTGBTFmL+OCPLDytn2Bb8=";
    executable = true;
  };
  # Included for convenience, removed from the final PR
  # nix store add-file ./ppc64/bootstrap-tools.tar.xz
  bootstrapTools = import <nix/fetchurl.nix> {
    url = "http://tarballs.nixos.org/stdenv-linux/powerpc64/ec90f8ea7355f843bd450cb5f8e9c7a693511e38/bootstrap-tools.tar.xz";
    sha256 = "sha256-/+Utfmpxn7T8LuBVTa2Z5mVaLv/5yRKTK/LzmPbqrww=";
  };
}
