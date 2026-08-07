{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  attrs,
  coverage,
  furo,
  ipython,
  msgpack,
  mypy,
  pre-commit,
  pyright,
  pytest,
  pytestCheckHook,
  pyyaml,
  setuptools,
  setuptools-scm,
  sphinx,
  sphinx-copybutton,
  sphinx-design,
  tomli-w,
}:

buildPythonPackage rec {
  pname = "msgspec";
  version = "0.20.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "jcrist";
    repo = "msgspec";
    tag = version;
    # Note that this hash changes after some time after release because they
    # use `$Format:%d$` in msgspec/_version.py, and GitHub produces different
    # tarballs depending on whether tagged commit is the last commit, see
    # https://github.com/NixOS/nixpkgs/issues/84312
    hash = "sha256-DWDmnSuo12oXl9NVfNhIOtWrQeJ9DMmHxOyHY33Datk=";
  };

  patches = [
    # Ext.code is backed by a long, not an int. int (with sizeof(int) < sizeof(long)) makes it return the high half
    # of the long on big-endian, so every code turns 0 or -1 when read.
    # Fixes TestExt suite, and runtime usage of msgpack.Ext(), on big-endian.
    # https://github.com/msgspec/msgspec/pull/1135
    ./1001-msgspec-Fix-backing-type-declaration-of-Ext-code.patch
  ];

  build-system = [
    setuptools
    setuptools-scm
  ];

  optional-dependencies = {
    dev = [
      coverage
      mypy
      pre-commit
      pyright
    ]
    ++ optional-dependencies.doc
    ++ optional-dependencies.test;
    doc = [
      furo
      ipython
      sphinx
      sphinx-copybutton
      sphinx-design
    ];
    test = [
      attrs
      msgpack
      pytest
    ]
    ++ optional-dependencies.yaml
    ++ optional-dependencies.toml;
    toml = [ tomli-w ];
    yaml = [ pyyaml ];
  };

  nativeCheckInputs = [
    pytestCheckHook
  ];

  # `tests/typing` runs type checkers
  enabledTestPaths = [ "tests/unit" ];

  pythonImportsCheck = [ "msgspec" ];

  meta = {
    description = "Module to handle JSON/MessagePack";
    homepage = "https://github.com/jcrist/msgspec";
    changelog = "https://github.com/jcrist/msgspec/releases/tag/${src.tag}";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ fab ];
  };
}
