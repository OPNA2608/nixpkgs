{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  cmake,
  ctestCheckHook,
  imath,
  libdeflate,
  pkg-config,
  libjxl,
  pkgsCross,
  python3Packages,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "openexr";
  version = "3.5.1";

  src = fetchFromGitHub {
    owner = "AcademySoftwareFoundation";
    repo = "openexr";
    tag = "v${finalAttrs.version}";
    hash = "sha256-a+OWifnXplV9SLicOnVOpaSD8+lwBx6j1/I40O26p/s=";
  };

  outputs = [
    "bin"
    "dev"
    "out"
    "doc"
  ];

  patches =
    [
      # Remove when version >= 3.5.3
      (fetchpatch {
        name = "0001-openexr-Fix-byte-swapped-deep-sample-count-table-on-BE.patch";
        url = "https://github.com/AcademySoftwareFoundation/openexr/commit/e27ee517642b57d694cd9130c30818b360ba8870.patch";
        hash = "sha256-vlucIxsEb6VB3GD7xCzkVodyV2sHquYYzhwV38MRdt0=";
      })
    ]
    # Disable broken test on musl libc
    # https://github.com/AcademySoftwareFoundation/openexr/issues/1556
    ++ lib.optional stdenv.hostPlatform.isMusl ./disable-iex-test.patch;

  # tests are determined to use /var/tmp on unix
  postPatch = ''
    cat <(find . -name tmpDir.h) <(echo src/test/OpenEXRCoreTest/main.cpp) | while read -r f ; do
      substituteInPlace $f --replace-fail '/var/tmp' "$TMPDIR"
    done
  '';

  cmakeFlags = lib.optional stdenv.hostPlatform.isStatic "-DCMAKE_SKIP_RPATH=ON";

  nativeBuildInputs = [
    cmake
    pkg-config
  ];
  propagatedBuildInputs = [
    imath
    libdeflate
  ];
  nativeCheckInputs = [
    ctestCheckHook
  ];

  strictDeps = true;

  # Without 'sse' enforcement tests fail on i686 as due to excessive precision as:
  #   error reading back channel B pixel 21,-76 got -nan expected -nan
  env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.hostPlatform.isi686 "-msse2 -mfpmath=sse";

  # https://github.com/AcademySoftwareFoundation/openexr/issues/1400
  doCheck = !stdenv.hostPlatform.isAarch32;

  disabledTests = lib.optionals stdenv.hostPlatform.isBigEndian [
    # https://github.com/AcademySoftwareFoundation/openexr/issues/1175
    # Not sure if these issues are specific to the tests, or if openexr in general is borked on big-endian.
    # Optimistically assuming the former here.
    "OpenEXRCore.testDWAACompression"
    "OpenEXRCore.testDWABCompression"
    "OpenEXRCore.testZstdCompression"
    "OpenEXR.testCompression"
    "OpenEXR.testConversion"
    "OpenEXR.testCopyDeepScanLine"
    "OpenEXR.testCopyDeepTiled"
    "OpenEXR.testCopyPixels"
    "OpenEXR.testCRgba"
    "OpenEXR.testDeepScanLineBasic"
    "OpenEXR.testDeepTiledBasic"
    "OpenEXR.testExistingStreams"
    "OpenEXR.testLargeDataWindowOffsets"
    "OpenEXR.testLJ2KBoundary"
    "OpenEXR.testRgba"
    "OpenEXR.testRgbaThreading"
    "OpenEXR.testSampleImages"
    "OpenEXR.testSharedFrameBuffer"
    "OpenEXR.testTiledCompression"
    "OpenEXR.testTiledCopyPixels"
    "OpenEXR.testTiledLineOrder"
    "OpenEXR.testTiledRgba"
  ];

  passthru.tests = {
    inherit libjxl;
    musl = pkgsCross.musl64.openexr;
    python = python3Packages.openexr;
  };

  __structuredAttrs = true;

  meta = {
    description = "High dynamic-range (HDR) image file format";
    homepage = "https://www.openexr.com";
    changelog = "https://github.com/AcademySoftwareFoundation/OpenEXR/blob/v${finalAttrs.version}/CHANGES.md";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ paperdigits ];
    platforms = lib.platforms.all;
  };
})
