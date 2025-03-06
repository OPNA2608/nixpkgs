/*
  # Updates

  Run `./fetch.sh` to update package sources from Git.
  Check for any minor version changes.
*/

{
  makeScopeWithSplicing',
  generateSplicesForMkScope,
  lib,
  stdenv,
  fetchurl,
  fetchgit,
  fetchpatch,
  fetchFromGitHub,
  makeSetupHook,
  makeWrapper,
  bison,
  cups ? null,
  harfbuzz,
  libGL,
  perl,
  python3,
  gstreamer,
  gst-plugins-base,
  gtk3,
  dconf,
  llvmPackages_15,
  overrideSDK,
  overrideLibcxx,
  darwin,

  # options
  developerBuild ? false,
  decryptSslTraffic ? false,
  debug ? false,
  config,
}:

let

  srcs = import ./srcs.nix { inherit lib fetchgit fetchFromGitHub; };

  qtCompatVersion = srcs.qtbase.version;

  patches = {
    qtbase = [
      ./qtbase.patch.d/0003-qtbase-mkspecs.patch
      ./qtbase.patch.d/0004-qtbase-replace-libdir.patch
      ./qtbase.patch.d/0005-qtbase-cmake.patch
      ./qtbase.patch.d/0006-qtbase-gtk3.patch
      ./qtbase.patch.d/0007-qtbase-xcursor.patch
      ./qtbase.patch.d/0008-qtbase-tzdir.patch
      ./qtbase.patch.d/0009-qtbase-qtpluginpath.patch
      ./qtbase.patch.d/0010-qtbase-assert.patch
      ./qtbase.patch.d/0011-fix-header_module.patch
    ];
    qtdeclarative = [
      ./qtdeclarative.patch
      # prevent headaches from stale qmlcache data
      ./qtdeclarative-default-disable-qmlcache.patch
      # add version specific QML import path
      ./qtdeclarative-qml-paths.patch
    ];
    qtlocation = lib.optionals stdenv.cc.isClang [
      # Fix build with Clang 16
      (fetchpatch {
        url = "https://github.com/boostorg/numeric_conversion/commit/50a1eae942effb0a9b90724323ef8f2a67e7984a.patch";
        stripLen = 1;
        extraPrefix = "src/3rdparty/mapbox-gl-native/deps/boost/1.65.1/";
        hash = "sha256-UEvIXzn387f9BAeBdhheStD/4M7en+rmqX8C6gstl6k=";
      })
    ];
    qtpim = [
      ## Upstream patches after the Qt6 transition that apply without problems & fix bugs

      (fetchpatch {
        name = "0001-qtpim-Use-QRegularExpression-instead-of-the-deprecated-QRegExp.patch";
        url = "https://github.com/qt/qtpim/commit/ad886f4fbedc5028bb4be499836d4d6f1de669e1.patch";
        hash = "sha256-UMix/TQQNhGnGSYVSGMaoNddqO6j4a4sCmYtn/NUOgo=";
      })
      (fetchpatch {
        name = "0002-qtpim-Remove-usage-of-deprecated-QLatin1Literal.patch";
        url = "https://github.com/qt/qtpim/commit/cc293592e4a430e42d6086ca5971ab4ac0222b81.patch";
        hash = "sha256-z1Z9BQuAdMoiEAutGTksrCcgjfkJi5C496T9xaY0CWQ=";
      })
      (fetchpatch {
        name = "0003-qtpim-Fix-QList-from-QSet-conversions.patch";
        url = "https://github.com/qt/qtpim/commit/f337e281e28904741a3b1ac23d15c3a83ef2bbc9.patch";
        hash = "sha256-zlxD45JnbhIgdJxMmGxGMUBcQPcgzpu3s4bLX939jL0=";
      })
      (fetchpatch {
        name = "0004-qtpim-Remove-usage-of-deprecated-QtAlgorithms.patch";
        url = "https://github.com/qt/qtpim/commit/847eda8c2054ef8c13c3389457792f5ec939a128.patch";
        hash = "sha256-KE0Hd6u0j1CujgZan48Ta4OAxJlvdBZChyCEz+YuYq0=";
      })
      (fetchpatch {
        name = "0005-qtpim-Add-missing-include.patch";
        url = "https://github.com/qt/qtpim/commit/a86100eb0e37a764399b1e06f73da0ceda5b00e9.patch";
        hash = "sha256-lrh+8CovGXNTk0x2puYMhd1IIUWk5Fm1tKLzLZBCmiQ=";
      })
      (fetchpatch {
        name = "0006-qtpim-Remove-usage-of-deprecated-API-from-the-declarative-plugins.patch";
        url = "https://github.com/qt/qtpim/commit/cc12dbb13368396cbb484547f0440584bec26fac.patch";
        hash = "sha256-tP7eq53D25e1UJnnSrnZYUEV8TP8lVUCy3Hgc7c2+8E=";
      })
      (fetchpatch {
        name = "0007-qtpim-More-QDateTime-QDate-to-QDate::startOfDay-fixes.patch";
        url = "https://github.com/qt/qtpim/commit/2aefdd8bd28a4decf9ef8381f5b255f39f1ee90c.patch";
        hash = "sha256-mg93QF3hi50igw1/Ok7fEs9iCaN6co1+p2/5fQtxTmc=";
      })
      (fetchpatch {
        name = "0008-qtpim-Adjust-unit-test-to-account-for-QList-index-from-int-to-qsizetype-change.patch";
        url = "https://github.com/qt/qtpim/commit/79b41af6a4117f5efb0298289e20c30b4d0b0b2e.patch";
        hash = "sha256-u+cLl4lu6r2+j5GAiasqbB6/OZPz5A6GpSB33vd/VBg=";
      })
      (fetchpatch {
        name = "0009-qtpim-Remove-invalid-method-overload-which-confuses-the-QML-engine.patch";
        url = "https://github.com/qt/qtpim/commit/5679a6141c76ae7d64c3acc8a87b1adb048289e0.patch";
        hash = "sha256-z8f8kLhC9CqBOfGPL8W9KJq7MwALAAicXfRkHiQEVJ4=";
      })
      (fetchpatch {
        name = "0010-qtpim-Specify-enum-flag-type-properly-in-unit-test.patch";
        url = "https://github.com/qt/qtpim/commit/a43cc24e57db8d3c3939fa540d67da3294dcfc5c.patch";
        hash = "sha256-SsYkxX6prxi8VRZr4az+wqawcRN8tR3UuIFswJL+3T4=";
      })
      (fetchpatch {
        name = "0011-qtpim-Remove-unused-method-in-unit-test.patch";
        url = "https://github.com/qt/qtpim/commit/f96d5e0307de938dbb38cf399af9d46192e3b8f5.patch";
        hash = "sha256-9Tg9AUVx9lncUQqjEcpF1WEMbkWHhgGkqLrThuajVb8=";
      })
      (fetchpatch {
        name = "0012-qtpim-Update-qHash-methods-to-return-size_t-instead-of-uint.patch";
        url = "https://github.com/qt/qtpim/commit/9c698155d82fc2b68a87c59d0443c33f9085b117.patch";
        hash = "sha256-rb8D8taaglhQikYSAPrtLvazgIw8Nga/a9+J21k8gIo=";
      })
      (fetchpatch {
        name = "0013-qtpim-Mark-virtual-methods-with-override-keyword.patch";
        url = "https://github.com/qt/qtpim/commit/f34cf2ff2b0f428d5b8a70763b29088075ebbd1c.patch";
        hash = "sha256-tNPOEVpx1eqHx5T23ueW32KxMQ/SB+TBCJ4PZ6SA3LI=";
      })
      (fetchpatch {
        name = "0014-qtpim-Fix-calendardemo-example.patch";
        url = "https://github.com/qt/qtpim/commit/a66590d473753bc49105d3132fb9e4150c92a14a.patch";
        hash = "sha256-RPRtGQ24NQYewnv6+IqYITpwD/XxuK68a1iKgFmKm3c=";
      })
      (fetchpatch {
        name = "0015-qtpim-Make-the-tests-pass-on-big-endian-systems.patch";
        url = "https://github.com/qt/qtpim/commit/7802f038ed1391078e27fa3f37d785a69314537b.patch";
        hash = "sha256-hogUXyPXjGE0q53PWOjiQbQ2YzOsvrJ7mo9djGIbjVQ=";
      })
      (fetchpatch {
        name = "0016-qtpim-Fix-some-deprecated-QChar-constructor-issues-in-unit-tests.patch";
        url = "https://github.com/qt/qtpim/commit/114615812dcf9398c957b0833e860befe15f840f.patch";
        hash = "sha256-yZ1qs8y5DSq8FDXRPyuSPRIzjEUTWAhpVide/b+xaLQ=";
      })
      (fetchpatch {
        name = "0017-qtpim-Add-label-group-field-to-display-label-detail.patch";
        url = "https://github.com/qt/qtpim/commit/29eac470383fcc68a2b9bcce5a26234c0ca618a1.patch";
        hash = "sha256-AYuVQMgo8wmR1atlizuezTFMhQ9hNkXc8320C2epQQ4=";
      })
      (fetchpatch {
        name = "0018-qtpim-Provide-interface-for-accessing-all-extended-metadata-from-collections.patch";
        url = "https://github.com/qt/qtpim/commit/5bdfb9127b3f6c9863def0578c7a8734a5156ea9.patch";
        hash = "sha256-asJNa8tcdtovVE579FjZg1CHeCmvRJ8otQeSrEdrXdQ=";
      })
      (fetchpatch {
        name = "0019-qtpim-Accessors-should-be-const.patch";
        url = "https://github.com/qt/qtpim/commit/a2bf7cdf05c264b5dd2560f799760b5508f154e4.patch";
        hash = "sha256-+YfPrKyOKnPkqFokwW/aDsEivg4TzdJwQpDdAtM+rQE=";
      })
      (fetchpatch {
        name = "0020-qtpim-Enforce-detail-access-constraints-in-contact-operations-by-default.patch";
        url = "https://github.com/qt/qtpim/commit/8765a35233aa21a932ee92bbbb92a5f8edd4dc68.patch";
        hash = "sha256-vp/enerVecEXz4zyxQ66DG+fVVWxI4bYnLj92qaaqNk=";
      })
      (fetchpatch {
        name = "0021-qtpim-Set-PLUGIN_CLASS_NAME-in-pro-files.patch";
        url = "https://github.com/qt/qtpim/commit/4b2bdce30bd0629c9dc0567af6eeaa1d038f3152.patch";
        hash = "sha256-2dXhkZyxPvY2KQq2veerAlpXkpU5/FeArWRlm1aOcEY=";
      })

      ## Patches that haven't been upstreamed

      (fetchpatch {
        name = "1001-qtpim-Fix-unit-test-tst_QContactManager::compareVariant_data.patch";
        url = "https://salsa.debian.org/qt-kde-team/qt/qtpim/-/raw/360682f88457b5ae7c92f32f574e51ccc5edbea0/debian/patches/1001_fix-qtdatetime-null-comparison.patch";
        hash = "sha256-k/rO9QjwSlRChwFTZLkxDjZWqFkua4FNbaNf1bJKLxc=";
      })
      (fetchpatch {
        name = "1002-qtpim-Avoid-crash-while-parsing-vCards-from-different-threads.patch";
        url = "https://salsa.debian.org/qt-kde-team/qt/qtpim/-/raw/360682f88457b5ae7c92f32f574e51ccc5edbea0/debian/patches/1002_Avoid-crash-while-parsing-vcards-from-different-threads.patch";
        hash = "sha256-zhayAoWgcmKosEGVBy2k6a2e6BxyVwfGX18tBbzqEk8=";
      })
      (fetchpatch {
        name = "1003-qtpim-adapt-to-JSON-parser-behavior-change-in-Qt-5.15.patch";
        url = "https://salsa.debian.org/qt-kde-team/qt/qtpim/-/raw/360682f88457b5ae7c92f32f574e51ccc5edbea0/debian/patches/1003_adapt_to_json_parser_change.patch";
        hash = "sha256-qAIa48hmDd8vMH/ywqW+22vISKai76XnjgFuB+tQbIU=";
      })
      (fetchpatch {
        name = "2001-qtpim-Revert-module-version-zeroing.patch";
        url = "https://salsa.debian.org/qt-kde-team/qt/qtpim/-/raw/360682f88457b5ae7c92f32f574e51ccc5edbea0/debian/patches/2000_revert_module_version.patch";
        hash = "sha256-6wg/eVu9J83yvIO428U1FX3otz58tAy6pCvp7fqOBKU=";
      })
    ];
    qtscript = [ ./qtscript.patch ];
    qtserialport = [ ./qtserialport.patch ];
    qtsystems = [
      # Fix crash if no X11 display available
      (fetchpatch {
        url = "https://salsa.debian.org/qt-kde-team/qt/qtsystems/-/raw/1a4df40671d6f1bb0657a9dfdae4cd9bd48fcf21/debian/patches/1005_check_XOpenDisplay.patch";
        hash = "sha256-/onla2nlUSySEgz2IYOYajx/LZkJzAKDyxwAZzy0Ivs=";
      })

      # Enable building with udisks support
      (fetchpatch {
        url = "https://salsa.debian.org/qt-kde-team/qt/qtsystems/-/raw/a23fd92222c33479d7f3b59e48116def6b46894c/debian/patches/2001_build_with_udisk.patch";
        hash = "sha256-B/z/+tai01RU/bAJSCp5a0/dGI8g36nwso8MiJv27YM=";
      })
    ];
    qtwebengine =
      [
        ./qtwebengine-link-pulseaudio.patch
        # Fixes Chromium build failure with Ninja 1.12.
        # See: https://bugreports.qt.io/browse/QTBUG-124375
        # Backport of: https://code.qt.io/cgit/qt/qtwebengine-chromium.git/commit/?id=a766045f65f934df3b5f1aa63bc86fbb3e003a09
        ./qtwebengine-ninja-1.12.patch
        # 5.15.17: Fixes 'converts to incompatible function type [-Werror,-Wcast-function-type-strict]'
        # in chromium harfbuzz dependency. This may be removed again if harfbuzz is updated
        # to include the upstream fixes: https://github.com/harfbuzz/harfbuzz/commit/d88269c827895b38f99f7cf741fa60210d4d5169
        # See https://trac.macports.org/ticket/70850
        (fetchpatch {
          url = "https://github.com/macports/macports-ports/raw/dd7bc40d8de48c762bf9757ce0a0672840c5d8c2/aqua/qt5/files/patch-qtwebengine_hb-ft.cc_error.diff";
          sha256 = "sha256-8/CYjGM5n2eJ6sG+ODTa8fPaxZSDVyKuInpc3IlZuyc=";
          extraPrefix = "";
        })
      ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [
        ./qtwebengine-darwin-no-platform-check.patch
        ./qtwebengine-mac-dont-set-dsymutil-path.patch
        ./qtwebengine-darwin-checks.patch
      ];
    qtwebkit =
      [
        (fetchpatch {
          name = "qtwebkit-python39-json.patch";
          url = "https://github.com/qtwebkit/qtwebkit/commit/78360c01c796b6260bf828bc9c8a0ef73c5132fd.patch";
          sha256 = "yCX/UL666BPxjnxT6rIsUrJsPcSWHhZwMFJfuHhbkhk=";
        })
        (fetchpatch {
          name = "qtwebkit-bison-3.7-build.patch";
          url = "https://github.com/qtwebkit/qtwebkit/commit/d92b11fea65364fefa700249bd3340e0cd4c5b31.patch";
          sha256 = "0h8ymfnwgkjkwaankr3iifiscsvngqpwb91yygndx344qdiw9y0n";
        })
        (fetchpatch {
          name = "qtwebkit-glib-2.68.patch";
          url = "https://github.com/qtwebkit/qtwebkit/pull/1058/commits/5b698ba3faffd4e198a45be9fe74f53307395e4b.patch";
          sha256 = "0a3xv0h4lv8wggckgy8cg8xnpkg7n9h45312pdjdnnwy87xvzss0";
        })
        (fetchpatch {
          name = "qtwebkit-darwin-handle.patch";
          url = "https://github.com/qtwebkit/qtwebkit/commit/5c272a21e621a66862821d3ae680f27edcc64c19.patch";
          sha256 = "9hjqLyABz372QDgoq7nXXXQ/3OXBGcYN1/92ekcC3WE=";
        })
        (fetchpatch {
          name = "qtwebkit-libxml2-api-change.patch";
          url = "https://github.com/WebKit/WebKit/commit/1bad176b2496579d760852c80cff3ad9fb7c3a4b.patch";
          sha256 = "WZEj+UuKhgJBM7auhND3uddk1wWdTY728jtiWVe7CSI=";
        })
        ./qtwebkit.patch
        ./qtwebkit-icu68.patch
        ./qtwebkit-cstdint.patch
      ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [
        ./qtwebkit-darwin-no-readline.patch
        ./qtwebkit-darwin-no-qos-classes.patch
      ];
    qttools = [ ./qttools.patch ];
  };

  addPackages =
    self:
    let
      qtModule = callPackage ../qtModule.nix {
        inherit patches;
        # Use a variant of mkDerivation that does not include wrapQtApplications
        # to avoid cyclic dependencies between Qt modules.
        mkDerivation = (callPackage ../mkDerivation.nix { wrapQtAppsHook = null; }) stdenv.mkDerivation;
      };

      callPackage = self.newScope {
        inherit
          qtCompatVersion
          qtModule
          srcs
          stdenv
          ;
      };
    in
    {

      inherit
        callPackage
        qtCompatVersion
        qtModule
        srcs
        ;

      mkDerivationWith = callPackage ../mkDerivation.nix { };

      mkDerivation = callPackage ({ mkDerivationWith }: mkDerivationWith stdenv.mkDerivation) { };

      qtbase = callPackage ../modules/qtbase.nix {
        inherit (srcs.qtbase) src version;
        patches = patches.qtbase;
        inherit
          bison
          cups
          harfbuzz
          libGL
          ;
        withGtk3 = !stdenv.hostPlatform.isDarwin;
        inherit dconf gtk3;
        inherit developerBuild decryptSslTraffic;
      };

      qt3d = callPackage ../modules/qt3d.nix { };
      qtcharts = callPackage ../modules/qtcharts.nix { };
      qtconnectivity = callPackage ../modules/qtconnectivity.nix { };
      qtdatavis3d = callPackage ../modules/qtdatavis3d.nix { };
      qtdeclarative = callPackage ../modules/qtdeclarative.nix { };
      qtdoc = callPackage ../modules/qtdoc.nix { };
      qtgamepad = callPackage ../modules/qtgamepad.nix { };
      qtgraphicaleffects = callPackage ../modules/qtgraphicaleffects.nix { };
      qtimageformats = callPackage ../modules/qtimageformats.nix { };
      qtlocation = callPackage ../modules/qtlocation.nix { };
      qtlottie = callPackage ../modules/qtlottie.nix { };
      qtmacextras = callPackage ../modules/qtmacextras.nix { };
      qtmultimedia = callPackage ../modules/qtmultimedia.nix {
        inherit gstreamer gst-plugins-base;
      };
      qtnetworkauth = callPackage ../modules/qtnetworkauth.nix { };
      qtpim = callPackage ../modules/qtpim.nix { };
      qtpositioning = callPackage ../modules/qtpositioning.nix { };
      qtpurchasing = callPackage ../modules/qtpurchasing.nix { };
      qtquick1 = null;
      qtquick3d = callPackage ../modules/qtquick3d.nix { };
      qtquickcontrols = callPackage ../modules/qtquickcontrols.nix { };
      qtquickcontrols2 = callPackage ../modules/qtquickcontrols2.nix { };
      qtremoteobjects = callPackage ../modules/qtremoteobjects.nix { };
      qtscript = callPackage ../modules/qtscript.nix { };
      qtsensors = callPackage ../modules/qtsensors.nix { };
      qtserialbus = callPackage ../modules/qtserialbus.nix { };
      qtserialport = callPackage ../modules/qtserialport.nix { };
      qtspeech = callPackage ../modules/qtspeech.nix { };
      qtsvg = callPackage ../modules/qtsvg.nix { };
      qtsystems = callPackage ../modules/qtsystems.nix { };
      qtscxml = callPackage ../modules/qtscxml.nix { };
      qttools = callPackage ../modules/qttools.nix { };
      qttranslations = callPackage ../modules/qttranslations.nix { };
      qtvirtualkeyboard = callPackage ../modules/qtvirtualkeyboard.nix { };
      qtwayland = callPackage ../modules/qtwayland.nix { };
      qtwebchannel = callPackage ../modules/qtwebchannel.nix { };
      qtwebengine = callPackage ../modules/qtwebengine.nix {
        # The version of Chromium used by Qt WebEngine 5.15.x does not build with clang 16 due
        # to the following errors:
        # * -Wenum-constexpr-conversion: This is a downgradable error in clang 16, but it is planned
        #   to be made into a hard error in a future version of clang. Patches are not available for
        #   the version of v8 used by Chromium in Qt WebEngine, and fixing the code is non-trivial.
        # * -Wincompatible-function-pointer-types: This is also a downgradable error generated
        #   starting with clang 16. Patches are available upstream that can be backported.
        # Because the first error is non-trivial to fix and suppressing it risks future breakage,
        # clang is pinned to clang 15. That also makes fixing the second set of errors unnecessary.
        stdenv = if stdenv.cc.isClang then overrideLibcxx llvmPackages_15.stdenv else stdenv;
        inherit (srcs.qtwebengine) version;
        inherit (darwin) bootstrap_cmds;
        python = python3;
      };
      qtwebglplugin = callPackage ../modules/qtwebglplugin.nix { };
      qtwebkit = callPackage ../modules/qtwebkit.nix { };
      qtwebsockets = callPackage ../modules/qtwebsockets.nix { };
      qtwebview = callPackage ../modules/qtwebview.nix { };
      qtx11extras = callPackage ../modules/qtx11extras.nix { };
      qtxmlpatterns = callPackage ../modules/qtxmlpatterns.nix { };

      env = callPackage ../qt-env.nix { };
      full =
        callPackage ({ env, qtbase }: env "qt-full-${qtbase.version}") { }
          # `with self` is ok to use here because having these spliced is unnecessary
          (
            with self;
            [
              qt3d
              qtcharts
              qtconnectivity
              qtdeclarative
              qtdoc
              qtgraphicaleffects
              qtimageformats
              qtlocation
              qtmultimedia
              qtquickcontrols
              qtquickcontrols2
              qtscript
              qtsensors
              qtserialport
              qtsvg
              qttools
              qttranslations
              qtvirtualkeyboard
              qtwebchannel
              qtwebengine
              qtwebsockets
              qtwebview
              qtx11extras
              qtxmlpatterns
              qtlottie
              qtdatavis3d
            ]
            ++ lib.optional (!stdenv.hostPlatform.isDarwin) qtwayland
            ++ lib.optional (stdenv.hostPlatform.isDarwin) qtmacextras
          );

      qmake = callPackage (
        { qtbase }:
        makeSetupHook {
          name = "qmake-hook";
          ${
            if stdenv.buildPlatform == stdenv.hostPlatform then
              "propagatedBuildInputs"
            else
              "depsTargetTargetPropagated"
          } =
            [ qtbase.dev ];
          substitutions = {
            inherit debug;
            fix_qmake_libtool = ../hooks/fix-qmake-libtool.sh;
          };
        } ../hooks/qmake-hook.sh
      ) { };

      wrapQtAppsHook = callPackage (
        {
          makeBinaryWrapper,
          qtbase,
          qtwayland,
        }:
        makeSetupHook {
          name = "wrap-qt5-apps-hook";
          propagatedBuildInputs = [
            qtbase.dev
            makeBinaryWrapper
          ] ++ lib.optional stdenv.hostPlatform.isLinux qtwayland.dev;
        } ../hooks/wrap-qt-apps-hook.sh
      ) { };
    };

  baseScope = makeScopeWithSplicing' {
    otherSplices = generateSplicesForMkScope "qt5";
    f = addPackages;
  };

  bootstrapScope = baseScope.overrideScope (
    final: prev: {
      qtbase = prev.qtbase.override { qttranslations = null; };
      qtdeclarative = null;
    }
  );

  finalScope = baseScope.overrideScope (
    final: prev: {
      # qttranslations causes eval-time infinite recursion when
      # cross-compiling; disabled for now.
      qttranslations =
        if stdenv.buildPlatform == stdenv.hostPlatform then bootstrapScope.qttranslations else null;
    }
  );
in
finalScope
