{ stdenv
, lib
, fetchFromGitLab
, fetchpatch
, cmake
, dbus
, dbus-test-runner
, dconf
, gnome
, libphonenumber
, libqtdbustest
, lomiri-api
, pkg-config
, protobuf
, qtbase
, qtdeclarative
, qtpim
, sqlite
, telepathy
, telepathy-mission-control
, wrapQtAppsHook
, xvfb-run
}:

stdenv.mkDerivation rec {
  pname = "history-service";
  version = "0.4";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-oCX+moGQewzstbpddEYYp1kQdO2mVXpWJITfvzDzQDI=";
  };

  patches = [
    # Deprecation warnings with Qt5.15, allow disabling -Werror
    # Remove when version > 0.4
    (fetchpatch {
      url = "https://gitlab.com/ubports/development/core/history-service/-/commit/1370777952c6a2efb85f582ff8ba085c2c0e290a.patch";
      hash = "sha256-Z/dFrFo7WoPZlKto6wNGeWdopsi8iBjmd5ycbqMKgxo=";
    })
    ./0001-Drop-deprecated-qt5_use_modules.patch
  ];

  postPatch = ''
    # Upstream's way of generating their schema doesn't work for us, don't quite understand why
    # (gdb) bt
    # #0  QSQLiteResult::prepare (this=0x4a4650, query=...) at qsql_sqlite.cpp:406
    # #1  0x00007ffff344bcf4 in QSQLiteResult::reset (this=0x4a4650, query=...) at qsql_sqlite.cpp:378
    # #2  0x00007ffff7f95f39 in QSqlQuery::exec (this=this@entry=0x7fffffffaad8, query=...) at kernel/qsqlquery.cpp:406
    # #3  0x00000000004084cb in SQLiteDatabase::dumpSchema (this=<optimized out>) at /build/source/plugins/sqlite/sqlitedatabase.cpp:148
    # #4  0x0000000000406d70 in main (argc=<optimized out>, argv=<optimized out>)
    #     at /build/source/plugins/sqlite/schema/generate_schema.cpp:56
    # (gdb) p lastError().driverText().toStdString()
    # $17 = {_M_dataplus = {<std::allocator<char>> = {<std::__new_allocator<char>> = {<No data fields>}, <No data fields>},
    #     _M_p = 0x4880d0 "Unable to execute statement"}, _M_string_length = 27, {
    #     _M_local_buf = "\033\000\000\000\000\000\000\000+\344\371\367\377\177\000", _M_allocated_capacity = 27}}
    # (gdb) p lastError().databaseText().toStdString()
    # $18 = {_M_dataplus = {<std::allocator<char>> = {<std::__new_allocator<char>> = {<No data fields>}, <No data fields>},
    #     _M_p = 0x48c480 "no such column: rowid"}, _M_string_length = 21, {
    #     _M_local_buf = "\025\000\000\000\000\000\000\000A\344\371\367\377\177\000", _M_allocated_capacity = 21}}
    #
    # This replacement script should hopefully achieve the same / a similar-enough result with just sqlite
    cp ${./update_schema.sh.in} plugins/sqlite/schema/update_schema.sh.in

    # Uses pkg_get_variable, cannot substitute prefix with that
    substituteInPlace daemon/CMakeLists.txt \
      --replace 'DESTINATION ''${SYSTEMD_USER_UNIT_DIR}' 'DESTINATION "${placeholder "out"}/lib/systemd/user"'

    # Queries qmake for the QML installation path, which returns a reference to Qt5's build directory
    substituteInPlace CMakeLists.txt \
      --replace "\''${QMAKE_EXECUTABLE} -query QT_INSTALL_QML" "echo $out/lib/qt-${qtbase.version}/qml"

    # Bad path concatenation
    substituteInPlace config.h.in \
      --replace '@CMAKE_INSTALL_PREFIX@/@HISTORY_PLUGIN_PATH@' '@HISTORY_PLUGIN_PATH@'

  '' + (if doCheck then ''
    substituteInPlace tests/common/dbus-services/CMakeLists.txt \
      --replace "\''${DBUS_SERVICES_DIR}/org.freedesktop.Telepathy.MissionControl5.service" "${telepathy-mission-control}/share/dbus-1/services/org.freedesktop.Telepathy.MissionControl5.service" \
      --replace "\''${DBUS_SERVICES_DIR}/org.freedesktop.Telepathy.AccountManager.service" "${telepathy-mission-control}/share/dbus-1/services/org.freedesktop.Telepathy.AccountManager.service" \
      --replace "\''${DBUS_SERVICES_DIR}/ca.desrt.dconf.service" "${dconf}/share/dbus-1/services/ca.desrt.dconf.service"

    substituteInPlace cmake/modules/GenerateTest.cmake \
      --replace '/usr/lib/dconf' '${lib.getLib dconf}/libexec' \
      --replace '/usr/lib/telepathy' '${lib.getLib telepathy-mission-control}/libexec'
  '' else ''
    sed -i -e '/add_subdirectory(tests)/d' CMakeLists.txt
  '');

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    qtbase
    sqlite
    wrapQtAppsHook
  ];

  buildInputs = [
    libphonenumber
    protobuf
    qtbase
    qtdeclarative
    qtpim
    telepathy
  ];

  nativeCheckInputs = [
    dbus
    dbus-test-runner
    dconf
    gnome.gnome-keyring
    telepathy-mission-control
    xvfb-run
  ];

  cmakeFlags = [
    # Many deprecation warnings with Qt5.15
    "-DENABLE_WERROR=OFF"
  ];

  preBuild = ''
    # SQLiteDatabase is used on host to generate SQL schemas
    # Tests also need this to use SQLiteDatabase for verifying correct behaviour
    export QT_PLUGIN_PATH=${lib.getBin qtbase}/lib/qt-${qtbase.version}/plugins
  '';

  # ContactMatcherTest failures, mostly on QSignalSpy's not seeing some signals (Qt5.15 problem?)
  doCheck = false;

  # Parallelism in tests seems to break things
  enableParallelChecking = false;

  checkPhase = ''
    runHook preCheck

    export HOME=$PWD
    dbus-run-session --config-file=${dbus}/share/dbus-1/session.conf -- \
      make test

    runHook postCheck
  '';

  meta = with lib; {
    description = "Service that provides call log and conversation history";
    longDescription = ''
      History service provides the database and an API to store/retrieve the call log (used by dialer-app) and the sms/mms history (used by messaging-app).

      See as well telepathy-ofono for incoming message events.

      Database location: ~/.local/share/history-service/history.sqlite
    '';
    homepage = "https://gitlab.com/ubports/development/core/history-service";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ OPNA2608 ];
  };
}
