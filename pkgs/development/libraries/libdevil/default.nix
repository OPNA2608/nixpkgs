{ lib, stdenv, fetchurl, libjpeg, libpng, libmng, lcms1, libtiff, openexr, libGL
, libX11, pkg-config, cmake, OpenGL
}:

stdenv.mkDerivation rec {

  pname = "libdevil";
  version = "1.8.0";

  src = fetchurl {
    url = "mirror://sourceforge/openil/DevIL-${version}.tar.gz";
    sha256 = "sha256-AHWXPufdifBQeHPiWArHgzZFLSnTSgcTSyCPROL+twk=";
  };

  outputs = [ "out" "dev" ];

  sourceRoot = "DevIL/DevIL";

  buildInputs = [ libjpeg libpng libmng lcms1 libtiff openexr libGL libX11 ]
    ++ lib.optionals stdenv.isDarwin [ OpenGL ];
  nativeBuildInputs = [ pkg-config cmake ];

  #configureFlags = [ "--enable-ILU" "--enable-ILUT" ];

  #preConfigure = ''
  #  sed -i 's, -std=gnu99,,g' configure
  #  sed -i 's,malloc.h,stdlib.h,g' src-ILU/ilur/ilur.c
  #'' + lib.optionalString stdenv.cc.isClang ''
  #  sed -i 's/libIL_la_CXXFLAGS = $(AM_CFLAGS)/libIL_la_CXXFLAGS =/g' lib/Makefile.in
  #'';

  #postConfigure = ''
  #  sed -i '/RESTRICT_KEYWORD/d' include/IL/config.h
  #'';

  patches =
    [
      #./ftbfs-libpng15.patch
      #./il_endian.h.patch
    ];

  postPatch = ''
    #for a in test/Makefile.in test/format_test/format_checks.sh.in ; do
    #  substituteInPlace $a \
    #    --replace /bin/bash ${stdenv.shell}
    #done
  '';

  meta = with lib; {
    homepage = "http://openil.sourceforge.net/";
    description = "An image library which can can load, save, convert, manipulate, filter and display a wide variety of image formats";
    license = licenses.lgpl2;
    platforms = platforms.mesaPlatforms;
    maintainers = [ ];
  };
}
