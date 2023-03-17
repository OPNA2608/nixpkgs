# TODO
# - meta
{ stdenv
, lib
, fetchFromGitHub
, autoreconfHook
, coreutils
, dbus
, glib
, installShellFiles
, kmod
, makeWrapper
, pkg-config
, systemd
, udev
}:

stdenv.mkDerivation rec {
  pname = "usb_moded";
  version = "0.86.0+mer63";

  src = fetchFromGitHub {
    owner = "sailfishos";
    repo = "usb-moded";
    rev = "mer/${version}";
    fetchSubmodules = true; # dbus-gmain
    hash = "sha256-VZ/Fz5ETOePOdrh+7QbEq/pMU8PcYichIWfkL0vLrrw=";
  };

  postPatch = ''
    substituteInPlace usb_moded.pc.in \
      --replace '/usr' "$out"
    substituteInPlace systemd/*.service \
      --replace '/usr' "$out" \
      --replace '/var' "$out/var" \
      --replace '/bin/kill' '${coreutils}/bin/kill'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    installShellFiles
    makeWrapper
    pkg-config
  ];

  buildInputs = [
    dbus
    glib
    kmod
    systemd
    udev
  ];

  enableParallelBuilding = true;

  configureFlags = [
    "--enable-systemd"
  ];

  postInstall = ''
    for header in usb_moded-{dbus,modes,appsync-dbus}.h; do
      install -Dm644 {src,$out/include/usb-moded}/$header
    done

    # where does this really need to go? some dbus-related thing
    install -Dm644 {src,$out/include/usb-moded}/com.meego.usb_moded.xml

    install -Dm644 {.,$out/lib/pkgconfig}/usb_moded.pc

    install -Dm644 {docs,$out/share/doc/usb_moded}/usb_moded-doc.txt

    cp debian/manpage.1 usb-moded.1
    installManPage usb-moded.1

    install -Dm644 {debian,$out/etc/dbus-1/system.d}/usb_moded.conf
    install -Dm644 {rpm,$out/etc/modprobe.d}/usb_moded.conf

    mkdir -p $out/etc/usb-moded
    cp -R config/{dyn-modes,diag,run,run-diag} $out/etc/usb-moded/
    install -Dm644 {config,$out/etc/usb-moded}/mass-storage-jolla.ini
    install -Dm644 {config,$out/etc/usb-moded}/10-usb-moded-defaults.ini

    mkdir -p $out/lib/systemd/system
    cp systemd/*.service $out/lib/systemd/system/
    install -Dm644 {systemd,$out/var/lib/environment/usb-moded}/usb-moded-args.conf
    install -Dm644 {systemd,$out/etc/tmpfiles.d}/usb-moded.conf

    install -Dm755 {systemd,$out/bin}/turn-usb-rescue-mode-off
    install -Dm755 {systemd,$out/sbin}/adbd-functionfs.sh

    install -Dm755 {scripts,$out/share/user-managerd/remove.d}/usb_mode_user_clear.sh

    wrapProgram $out/bin/turn-usb-rescue-mode-off \
      --prefix PATH : ${lib.makeBinPath [ dbus ]}
  '';
}
