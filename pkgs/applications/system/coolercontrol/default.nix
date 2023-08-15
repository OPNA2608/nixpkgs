{ lib
, fetchFromGitLab
, callPackage
, qt6Packages
}:

let
  version = "0.17.0";

  src = fetchFromGitLab {
    owner = "coolercontrol";
    repo = "coolercontrol";
    rev = version;
    hash = "sha256-HZpJd3/Hk6icf+GFwW+inz7j/jFPlAZJVQbt0enK7xs=";
  };

  meta = with lib; {
    description = "Monitor and control your cooling devices";
    homepage = "https://gitlab.com/coolercontrol/coolercontrol";
    license = licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ codifryed OPNA2608 ];
  };

  applySharedDetails = drv: drv { inherit version src meta; };
in
rec {
  coolercontrold = applySharedDetails (callPackage ./coolercontrold.nix { });

  coolercontrol-liqctld = applySharedDetails (callPackage ./coolercontrol-liqctld.nix { });

  coolercontrol-gui = applySharedDetails (qt6Packages.callPackage ./coolercontrol-gui.nix { });
}
