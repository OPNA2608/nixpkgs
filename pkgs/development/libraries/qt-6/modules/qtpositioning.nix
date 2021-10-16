{ qtModule
, qtbase
, libwebp
, jasper
, libmng
, zlib
, pkg-config
, openssl
, qtserialport
, qtdeclarative
}:

qtModule {
  pname = "qtpositioning";
  qtInputs = [ qtbase qtdeclarative qtserialport ];
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];
}
