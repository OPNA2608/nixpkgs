{ lib
, stdenv
, fetchFromGitHub
, fetchpatch
, qtbase
, qtquick1
, qmake
, qtmultimedia
, utmp
}:

stdenv.mkDerivation {
  pname = "qmltermwidget";
  version = "unstable-2022-01-09";

  src = fetchFromGitHub {
    owner = "Swordfish90";
    repo = "qmltermwidget";
    rev = "63228027e1f97c24abb907550b22ee91836929c5";
    hash = "sha256-aVaiRpkYvuyomdkQYAgjIfi6a3wG2a6hNH1CfkA2WKQ=";
  };

  patches = [
    # These 5 patches allow lomiri-terminal-app to use this version of qmltermwidget
    # Remove when https://github.com/Swordfish90/qmltermwidget/pull/39 merged
    (fetchpatch {
      name = "0001-qmltermwidget-Expose-ColorSchemeManager-and-ColorScheme-to-QML.patch";
      url = "https://github.com/Swordfish90/qmltermwidget/pull/39/commits/d8834e291bdc8613156d5883b5b3975fce9b4372.patch";
      hash = "sha256-CCt66VR8QKn6EATWn4fQLW8P4i1QGbj1/hV4CQ28qhw=";
    })
    (fetchpatch {
      name = "0002-qmltermwidget-Expose-QMLTermWidget-foreground-and-background-colors-to-QML.patch";
      url = "https://github.com/Swordfish90/qmltermwidget/pull/39/commits/75a7a1ae11ff12516e7e53ea29662c1eb4d280d5.patch";
      hash = "sha256-gWxKDrZMLyKQNhLjayQZ5u5fkF3ZYtMTlkQcHOWe+PE=";
    })
    (fetchpatch {
      name = "0003-qmltermwidget-Make-QmlTermWidget-scrollbarCurrentValue-property-writable.patch";
      url = "https://github.com/Swordfish90/qmltermwidget/pull/39/commits/b3210f8936dfc4645b5e49c52e02e4385befe742.patch";
      hash = "sha256-n7oB68xk2CPDZRVACfytyv11638cn72/4QmF9FhhiLM=";
    })
    (fetchpatch {
      name = "0004-qmltermwidget-Add-QMLTermWidget-methods-to-query-whether-clipboard-selection-are-set.patch";
      url = "https://github.com/Swordfish90/qmltermwidget/pull/39/commits/eae6156cb7b857d07cb2699e0aed9901fe7ca0ed.patch";
      hash = "sha256-tc2sZDwXB018roEGD0pBN3rmp0ggJWZlYzRbkKw9wUs=";
    })
    (fetchpatch {
      name = "0005-qmltermwidget-Apply-color-scheme-if-changed.patch";
      url = "https://github.com/Swordfish90/qmltermwidget/pull/39/commits/ffc6b2b2a20ca785f93300eca93c25c4b74ece17.patch";
      hash = "sha256-ps4OmL9xAph4x7Zo3wvLNFcy+BDjaA+zmQghX2sW1dI=";
    })
  ];

  nativeBuildInputs = [ qmake ];

  buildInputs = [
    qtbase
    qtquick1
    qtmultimedia
  ] ++ lib.optional stdenv.isDarwin utmp;

  postPatch = ''
    substituteInPlace qmltermwidget.pro \
      --replace '$$[QT_INSTALL_QML]' '$$PREFIX/${qtbase.qtQmlPrefix}/'
  '';

  dontWrapQtApps = true;

  meta = {
    description = "A QML port of qtermwidget";
    homepage = "https://github.com/Swordfish90/qmltermwidget";
    license = lib.licenses.gpl2;
    platforms = with lib.platforms; linux ++ darwin;
    maintainers = with lib.maintainers; [ skeidel ];
  };
}
