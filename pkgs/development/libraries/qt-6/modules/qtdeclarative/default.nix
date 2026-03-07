{
  fetchpatch,
  qtModule,
  qtbase,
  qtlanguageserver,
  qtshadertools,
  qtsvg,
  openssl,
  darwin,
  stdenv,
  lib,
  pkgsBuildBuild,
  replaceVars,
}:

qtModule {
  pname = "qtdeclarative";

  propagatedBuildInputs = [
    qtbase
    qtlanguageserver
    qtshadertools
    qtsvg
    openssl
  ];
  strictDeps = true;

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.sigtool
  ];

  patches = [
    # don't cache bytecode of bare qml files in the store, as that never gets cleaned up
    (replaceVars ./dont-cache-nix-store-paths.patch {
      nixStore = builtins.storeDir;
    })
    # add version specific QML import path
    ./use-versioned-import-path.patch
    # Fix common crash
    # https://bugreports.qt.io/browse/QTBUG-140018
    (fetchpatch {
      url = "https://invent.kde.org/qt/qt/qtdeclarative/-/commit/2b7f93da38d41ffaeb5322a7dca40ec26fc091a1.diff";
      hash = "sha256-AOXey18lJlswpZ8tpTTZeFb0VE9k1louXy8TPPGNiA4=";
    })
    ## Fix another common crash
    ## https://bugreports.qt.io/browse/QTBUG-139626
    #(fetchpatch {
    #  url = "https://invent.kde.org/qt/qt/qtdeclarative/-/commit/0de0b0ffdb44d73c605e20f00934dfb44bdf7ad9.diff";
    #  hash = "sha256-DCoaSxH1MgywGXmmK21LLzCBi2KAmJIv5YKpFS6nw7M=";
    #})

    #(fetchpatch {
    #  url = "https://github.com/qt/qtdeclarative/commit/55ecea7a78997a6fa2e4cc0b0b8c421fa2106a13.patch";
    #  revert = true;
    #  hash = "sha256-5HV9udhfmvzHz0XS4MlCSoCtehvhv4sgOH2uHbjae1g=";
    #})

    #(fetchpatch {
    #  url = "https://github.com/qt/qtdeclarative/commit/6be33f6a54704e3563c265c71f3c163c548f8d7b.patch";
    #  revert = true;
    #  hash = "sha256-e66x5RolfOrxDOBB5BKcv08Bm8gBxxdOl8vXc0VXvvw=";
    #})
    #~/Development/nixpkgs/0001-Revert-QtQml-Better-protect-QQmlTypeLoader-shared-da.patch

    ########
    (fetchpatch {
      url = "https://github.com/qt/qtdeclarative/commit/e0e4e76e62b38dabb9dfdba24e70679e80ef7ac8.patch";
      hash = "sha256-9BtuZ2Uw14tLeCL7xfbgkLYfJT4eIdrTpSSmzuY97tg=";
    })
    (fetchpatch {
      url = "https://github.com/qt/qtdeclarative/commit/21c23839ee291eec03616cf3e036441d670922e1.patch";
      hash = "sha256-ypLZnzW/WXltUEYB99Wd43g1nbAMZ/fcenCVVz4WgWU=";
    })
    (fetchpatch {
      url = "https://github.com/qt/qtdeclarative/commit/c85d635d5f0188c42e03fb604c770ebaecc7d761.patch";
      hash = "sha256-yO4dmPthP7keGkyI2Wh43AgrluLg6NAcAXTf4RyhYjI=";
    })
    (fetchpatch {
      url = "https://github.com/qt/qtdeclarative/commit/ad900b8ae020fe4a8a4471b70c2a7f708da7a047.patch";
      hash = "sha256-bASf6cjOkkeqW+aKa4rYkzafI+cNArAhwq7SYoB67R4=";
    })
    (fetchpatch {
      url = "https://github.com/qt/qtdeclarative/commit/d27164a1cb514d89c81e16f9b2a3f2e219e6a45e.patch";
      hash = "sha256-U1BionpxvkLogMCHTo/W6InPuLNPBf9BPn3e6BPxSd4=";
    })
    (fetchpatch {
      url = "https://github.com/qt/qtdeclarative/commit/f6830a6dd44a1cda51ec038d6561e8acf5d96ede.patch";
      hash = "sha256-8rHP6LLDDSDqOsE1bKTOuz8PO/HPQ2cLXLdl+juGGgE=";
    })
    (fetchpatch {
      url = "https://github.com/qt/qtdeclarative/commit/60297d4d1e17705c128d11a1ef6f200e59ba4708.patch";
      includes = [
        "src/quickvectorimage/generator/qsvgvisitorimpl.cpp"
      ];
      hash = "sha256-Qn6WEqIPm9DPrvUMj0cKU0EphsTmiDbxhO0mx+sLNMM=";
    })
    (fetchpatch {
      url = "https://github.com/qt/qtdeclarative/commit/596120085b5dbb060e92dad495e64b3cf13fad33.patch";
      hash = "sha256-jgm5/VzSjXWOTaX91PHsacnnTVUOJVbRMUA3AbIaKDQ=";
    })
    (fetchpatch {
      url = "https://github.com/qt/qtdeclarative/commit/e9e31cca71a578f9497cc8ef489474b90f7d8cf9.patch";
      hash = "sha256-iQnlrzeuKgLOXFqoxD2hvSvGU4lnflny2rPIPNmt7p4=";
    })
  ];

  cmakeFlags = [
    "-DQt6ShaderToolsTools_DIR=${pkgsBuildBuild.qt6.qtshadertools}/lib/cmake/Qt6ShaderTools"
    # for some reason doesn't get found automatically on Darwin
    "-DPython_EXECUTABLE=${lib.getExe pkgsBuildBuild.python3}"
  ]
  # Conditional is required to prevent infinite recursion during a cross build
  ++ lib.optionals (!stdenv.buildPlatform.canExecute stdenv.hostPlatform) [
    "-DQt6QmlTools_DIR=${pkgsBuildBuild.qt6.qtdeclarative}/lib/cmake/Qt6QmlTools"
  ];

  meta.maintainers = with lib.maintainers; [
    nickcao
    outfoxxed
  ];
}
