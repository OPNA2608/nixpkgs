let
  makeTest = import ./make-test-python.nix;
in
{
  x11 = makeTest (
    { lib, ... }:
    {
      name = "maliit-x11";
      meta.maintainers = [ lib.maintainers.OPNA2608 ];

      nodes.machine =
        { config, pkgs, ... }:
        {
          imports = [ ./common/x11.nix ];

          services.xserver.enable = true;

          environment = {
            systemPackages =
              [
                # maliit-server wrapped with a keyboard plugin
                (pkgs.maliit-framework.passthru.wrapServerWithPlugin {
                  # maliit-keyboard does have its own binary, so this wrapper isn't necessary for it, but we don't have
                  # any other Maliit plugins packaged to test this with.
                  pluginPackage = pkgs.maliit-keyboard;
                  binaryName = "maliit-keyboard";
                })

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

        machine.send_chars("maliit-keyboard &\n")
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
}
