{ stdenv
, lib
, fetchFromGitHub
, fetchpatch
, gitUpdater
, cmake
, pkg-config
, python3
, doxygen
, libxslt
, boost
, capnproto
, egl-wayland
, freetype
, glib
, glm
, glog
, libdrm
, libepoxy
, libevdev
, libglvnd
, libinput
, libuuid
, libsystemtap
, libxcb
, libxkbcommon
, libxmlxx
, yaml-cpp
, lttng-ust
, mesa
, nettle
, protobuf
, udev
, wayland
, xorg
, xwayland
, dbus
, gtest
, umockdev
}:

let
  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  pythonEnv = python3.withPackages(ps: with ps; [
    pillow
  ] ++ lib.optionals doCheck [
    pygobject3
    python-dbusmock
  ]);
in

stdenv.mkDerivation rec {
  pname = "mir";
  version = "1.8.2";

  src = fetchFromGitHub {
    owner = "MirServer";
    repo = "mir";
    rev = "v${version}";
    hash = "sha256-O1R5qMNoF7Fo6JhUQ9WpIxDM8JTWOvyHFMh1aO/Vv2s=";
  };

  patches = [
    # These four patches fix various path concatenation problems and missing GNUInstallDirs variable uses that affect
    # install locations and generated pkg-config files
    # Backported from MirServer/mir/pull/2786
    ./0001-mir_1.x-Use-better-concatenation-for-pkg-config-paths.patch
    ./0002-mir_1.x-Improve-mirtest-pkg-config.patch
    ./0003-mir_1.x-Fix-GNUInstallDirs-variable-concatenations-in-CMake.patch
    ./0004-mir_1.x-Use-more-GNUInstallDirs-variables-non-FULL-variants-.patch

    # Fixes naming conflict between Xlib & capnproto
    (fetchpatch {
      name = "1001-mir-work-around-xlib-capnproto-naming-conflict.patch";
      url = "https://github.com/MirServer/mir/commit/dbd38ebae09c6ab91849f5a41c883bfbd8b47291.patch";
      hash = "sha256-OwzXtVeyNWCFsLznN0FpHP/kBz7UrYa3HAEbJpcd/F8=";
    })
    # Fixes GTEST_DISALLOW_ASSIGN error
    (fetchpatch {
      name = "1002-mir-dont-use-GTEST_DISALLOW_ASSIGN.patch";
      url = "https://github.com/MirServer/mir/commit/7ccc9d4f880a98f0e80c88ee4e2ed88213433093.patch";
      hash = "sha256-JC4u8evOHLRYJMprJOD+XFkbygXxTMuRy82uMcqjh3U=";
    })
    # Fixes ICE on GCC-12+
    # TODO this patch is marked in Debian as taken from upstream, but I can't find this commit on MirServer/Mir?
    (fetchpatch {
      name = "1003-mir-workaround-gcc-ICE-bug.patch";
      url = "https://salsa.debian.org/mir-server-team/mir/-/raw/8c256c7fc088b21a166a2f536681050c735a634c/debian/patches/1003-workaround-gcc-ICE-bug.patch";
      hash = "sha256-y/+IfLW2ck5D0d9qT4ztAjasYOKzI33pATQLyb0OZuE=";
    })
    # Fixes segfaults when trying to mock X11 in some tests
    # Fixed in 2.10.0
    (fetchpatch {
      name = "1004-mir-XInitThreads-if-mock-exists.patch";
      url = "https://github.com/MirServer/mir/commit/473c51b4e8555768f2c0997d60d640ac4dce76dc.patch";
      hash = "sha256-JLmNub7aLGS+LIHK6ZcLQIqhSmSm9XNZzPYPdECC8NE=";
    })
  ];

  postPatch = ''
    # Fix scripts that get run in tests
    patchShebangs tools/detect_fd_leaks.bash

    # Fix LD_PRELOADing in tests
    for needsPreloadFixing in \
      tests/umock-acceptance-tests/CMakeLists.txt \
      tests/unit-tests/platforms/mesa/kms/CMakeLists.txt \
      tests/unit-tests/platforms/mesa/x11/CMakeLists.txt \
      tests/unit-tests/CMakeLists.txt
    do
      substituteInPlace $needsPreloadFixing \
        --replace 'LD_PRELOAD=libumockdev-preload.so.0' 'LD_PRELOAD=${lib.getLib umockdev}/lib/libumockdev-preload.so.0'
    done

    # Patch in which tests we want to skip
    substituteInPlace cmake/MirCommon.cmake \
      --replace 'set(test_exclusion_filter)' 'set(test_exclusion_filter "${lib.strings.concatStringsSep ":" [
        # Work by draining /dev/random of its entropy, either hang or take too long to complete
        # Disabled in later Mir releases due to their tendency to hang
        "MirCookieAuthority.given_low_entropy_does_not_hang_or_crash"
        "MirCookieAuthority.makes_cookies_quickly"
        # Wait seemingly indefinitely, don't know why
        # Mirclient component completely removed since 2.5, closure/fix unlikely
        "TestClientInput.keeps_num_lock_state_after_focus_change"
        "TestClientInput.reestablishes_num_lock_state_in_client_with_surface_keymap"
      ]}")'

    # Fix Xwayland default
    substituteInPlace src/miral/x11_support.cpp \
      --replace '/usr/bin/Xwayland' '${xwayland}/bin/Xwayland'

    # Fix date in generated docs not honouring SOURCE_DATE_EPOCH
    # Install docs to correct dir
    substituteInPlace cmake/Doxygen.cmake \
      --replace '"date"' '"date" "--date=@'"$SOURCE_DATE_EPOCH"'"' \
      --replace "\''${CMAKE_INSTALL_PREFIX}/share/doc/mir-doc" "\''${CMAKE_INSTALL_DOCDIR}"
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    doxygen
    libxslt
    lttng-ust # lttng-gen-tp
    pkg-config
    pythonEnv
  ];

  buildInputs = [
    boost
    capnproto
    egl-wayland
    freetype
    glib
    glm
    glog
    libdrm
    libepoxy
    libevdev
    libglvnd
    libinput
    libuuid
    libsystemtap
    libxcb
    libxkbcommon
    libxmlxx
    yaml-cpp
    lttng-ust
    mesa
    nettle
    protobuf
    udev
    wayland
    xorg.libX11
    xorg.libXcursor
    xorg.xorgproto
    xwayland
  ];

  nativeCheckInputs = [
    dbus
  ];

  checkInputs = [
    gtest
    umockdev
  ];

  buildFlags = [ "all" "doc" ];

  cmakeFlags = [
    "-DMIR_PLATFORM='mesa-kms;mesa-x11;eglstream-kms;wayland'"
    "-DMIR_ENABLE_TESTS=${if doCheck then "ON" else "OFF"}"
    # These get built but don't get executed by default, yet they get installed when tests are enabled
    "-DMIR_BUILD_PERFORMANCE_TESTS=OFF"
    "-DMIR_BUILD_PLATFORM_TEST_HARNESS=OFF"
    # Older version, gained more compiler warnings over the years
    "-DMIR_FATAL_COMPILE_WARNINGS=OFF"
    # Hang
    "-DMIR_BUILD_INTERPROCESS_TESTS=OFF"
    # Can't start?
    # Unable to find executable: <wlcs>/libexec/wlcs/wlcs --gtest_filter=-ClientSurfaceEventsTest.frame_timestamp_increases:<...>:SubsurfaceTest.place_above_simple /build/source/build/lib/miral_wlcs_integration.so
    "-DMIR_ENABLE_WLCS_TESTS=OFF"
  ];

  inherit doCheck;

  outputs = [ "out" "dev" "doc" ];

  passthru = {
    updateScript = gitUpdater {
      rev-prefix = "v";
    };
    # More of an example than a fully functioning shell, some notes for the adventurous:
    # - ~/.config/miral-shell.config is one possible user config location,
    #   accepted options=value are according to `mir-shell --help`
    # - default icon theme setting is DMZ-White, needs vanilla-dmz installed & on XCURSOR_PATH
    #   or setting to be changed to an available theme
    # - terminal emulator setting may need to be changed if miral-terminal script
    #   does not know about preferred terminal
    providedSessions = [ "mir-shell" ];
  };

  meta = with lib; {
    description = "A display server and Wayland compositor developed by Canonical";
    homepage = "https://mir-server.io";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ onny OPNA2608 ];
    platforms = platforms.linux;
  };
}
