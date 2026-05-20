let
  makeTest = import ./make-test-python.nix;

  wrappedMaliit =
    pkgs: packagePath: binaryName:
    pkgs.maliit-framework.passthru.wrapServerWithPlugin {
      pluginPackage = builtins.foldl' (pkgsSet: subpath: pkgsSet.${subpath}) pkgs packagePath;
      inherit binaryName;
    };

  pkgsPathToString =
    pkgpath: if (builtins.isList pkgpath) then (builtins.concatStringsSep "-" pkgpath) else pkgpath;

  makeMaliitTest =
    maliitKeyboardPackagePath:
    makeTest (
      { lib, ... }:
      {
        name = "maliit-server-wrapper-${pkgsPathToString maliitKeyboardPackagePath}";
        meta.maintainers = [ lib.maintainers.OPNA2608 ];

        nodes.machine =
          { config, pkgs, ... }:
          {
            imports = [ ./common/x11.nix ];

            services.xserver.enable = true;

            environment = {
              systemPackages = [
                # maliit-server wrapped with a keyboard plugin
                (wrappedMaliit pkgs maliitKeyboardPackagePath (pkgsPathToString maliitKeyboardPackagePath))

                # example app plays nicely with IM
                pkgs.maliit-framework.examples
              ];
              variables = {
                GTK_IM_MODULE = "Maliit";
                QT_IM_MODULE = "Maliit";
              };
            };
          };

        enableOCR = true;

        testScript = ''
          machine.wait_for_x()

          machine.succeed("env DISPLAY=:0 xterm >&2 &")
          machine.sleep(5)

          machine.send_chars("${pkgsPathToString maliitKeyboardPackagePath} &\n")
          machine.sleep(5)

          machine.send_chars("maliit-exampleapp-plainqt\n")
          machine.sleep(5)
          machine.screenshot("maliit-server-wrapper_initial")

          machine.send_key("tab")
          machine.sleep(5)

          machine.wait_for_text("English")
          machine.screenshot("maliit-server-wrapper_works")
        '';
      }
    );
in
builtins.listToAttrs (
  builtins.map
    (pkgpath: {
      name = pkgsPathToString pkgpath;
      value = makeMaliitTest pkgpath;
    })
    [
      "maliit-keyboard"
      ([
        "lomiri"
        "lomiri-keyboard"
      ])
    ]
)
