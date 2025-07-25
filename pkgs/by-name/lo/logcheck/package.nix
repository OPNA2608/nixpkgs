{
  lib,
  stdenv,
  fetchurl,
  lockfileProgs,
  perlPackages,
}:

stdenv.mkDerivation rec {
  pname = "logcheck";
  version = "1.4.5";
  _name = "logcheck_${version}";

  src = fetchurl {
    url = "mirror://debian/pool/main/l/logcheck/${_name}.tar.xz";
    sha256 = "sha256-enUxHYVhdiDQLMAnQnRjx/mvIEHgL8k/W8Jda6PMrfE=";
  };

  prePatch = ''
    # do not set sticky bit in nix store.
    substituteInPlace Makefile --replace 2750 0750
  '';

  preConfigure = ''
    substituteInPlace src/logtail --replace "/usr/bin/perl" "${perlPackages.perl}/bin/perl"
    substituteInPlace src/logtail2 --replace "/usr/bin/perl" "${perlPackages.perl}/bin/perl"

    sed -i -e 's|! -f /usr/bin/lockfile|! -f ${lockfileProgs}/bin/lockfile|' \
           -e 's|^\([ \t]*\)lockfile-|\1${lockfileProgs}/bin/lockfile-|' \
           -e "s|/usr/sbin/logtail2|$out/sbin/logtail2|" \
           -e 's|mime-construct|${perlPackages.mimeConstruct}/bin/mime-construct|' \
           -e 's|\$(run-parts --list "\$dir")|"$dir"/*|' src/logcheck
  '';

  makeFlags = [
    "DESTDIR=$(out)"
    "SBINDIR=sbin"
    "BINDIR=bin"
    "SHAREDIR=share/logtail/detectrotate"
  ];

  meta = with lib; {
    description = "Mails anomalies in the system logfiles to the administrator";
    longDescription = ''
      Mails anomalies in the system logfiles to the administrator.

      Logcheck helps spot problems and security violations in your logfiles automatically and will send the results to you by e-mail.
      Logcheck was part of the Abacus Project of security tools, but this version has been rewritten.
    '';
    homepage = "https://salsa.debian.org/debian/logcheck";
    license = licenses.gpl2Plus;
  };
}
