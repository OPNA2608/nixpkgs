# TODO
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitLab
, accounts-qt
, ayatana-indicator-messages
, cmake
, evolution-data-server
, folks
, libaccounts-glib
, libnotify
, libphonenumber
, lomiri-url-dispatcher
, pkg-config
, protobuf
, qtbase
, qtpim
, systemd
}:

stdenv.mkDerivation rec {
  pname = "address-book-service";
  version = "unstable-2023-04-22";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = "10ec3ed3cc9043d67fac17af341eb61e1705899c";
    hash = "sha256-9w5qb49ykKb+WxZAYMClmXs24wZTzLo4Z+l/zgbIc7w=";
  };

  postPatch = ''
    substituteInPlace contacts/CMakeLists.txt \
      --replace '"''${CMAKE_INSTALL_LIBDIR}/qt5/plugins"' '"${placeholder "out"}/${qtbase.qtPluginPrefix}"'

    # Queries evolution-data-server's pkg-config for moduledir, variable doesn't use prefix variable so must manually replace wrong prefix
    substituteInPlace eds-extension/CMakeLists.txt \
      --replace 'OUTPUT_VARIABLE EDS_MODULES_DIR' 'COMMAND sed -e "s|${evolution-data-server}|${placeholder "out"}|" OUTPUT_VARIABLE EDS_MODULES_DIR'

    # Use better way of getting systemd user unit dir
    substituteInPlace systemd/CMakeLists.txt \
      --replace 'pkg_get_variable(SYSTEMD_USER_UNIT_DIR systemd systemduserunitdir)' \
        'execute_process(COMMAND pkg-config --define-variable=prefix=${placeholder "out"} --variable systemduserunitdir systemd OUTPUT_VARIABLE SYSTEMD_USER_UNIT_DIR OUTPUT_STRIP_TRAILING_WHITESPACE)'

    # contacts plugin missing libphonenumber link. without it plugin fails to load, qtpim stores & dereferences a NULL engine and address-book-app segfaults
    sed -i \
      -e '/target_link_libraries(''${QCONTACTS_BACKEND}/a ''${LibPhoneNumber_LIBRARIES}' \
      contacts/CMakeLists.txt
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    accounts-qt
    ayatana-indicator-messages
    evolution-data-server
    folks
    libaccounts-glib
    libnotify
    libphonenumber
    lomiri-url-dispatcher
    protobuf
    qtbase
    qtpim
    systemd
  ];

  dontWrapQtApps = true;

  cmakeFlags = [
    "-DENABLE_TESTS=${lib.boolToString doCheck}"
  ];

  # TODO
  doCheck = false;
}
