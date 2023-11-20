import ./make-test-python.nix ({ pkgs, lib, ... }: {
  name = "lomiri";

  meta = {
    maintainers = lib.teams.lomiri.members;
  };

  nodes.machine = { config, ... }: {
    imports = [
      ./common/auto.nix
      ./common/user-account.nix
    ];

    test-support.displayManager.auto = {
      enable = true;
      user = "alice";
    };

    services.xserver = {
      enable = true;
      displayManager.defaultSession = lib.mkForce "lomiri";
    };

    programs.lomiri.enable = true;

    environment.systemPackages = with pkgs; [
      (writeShellApplication {
        name = "check-waylandinfo";
        runtimeInputs = [ wayland-utils ];
        text = ''
          wayland-info | tee /tmp/test-wayland.out && touch /tmp/test-wayland-exit-ok
        '';
      })
    ];
  };

  enableOCR = true;

  testScript = { nodes, ... }: let
    settingsPages = [
      { name = "wifi"; element = "networks"; }
      { name = "bluetooth"; element = "None detected"; }
      { name = "vpn"; element = "Manual"; }
      { name = "appearance"; element = "Background image"; }
      { name = "desktop"; element = "Icon size"; }
      { name = "sound"; element = "Silent Mode"; }
      { name = "language"; element = "English"; }
      { name = "notification"; element = "Apps that notify"; }
      { name = "gestures"; element = "Edge drag"; }
      { name = "mouse"; element = "Cursor speed"; }
      { name = "timedate"; element = "UTC"; }
    ];
  in ''
    def maximise_new_window(machine: Machine):
        """
        Maximise the just-opened window, and handle Lomiri potentially seeing a spurious meta
        and deciding to open the launcher menu back up.
        """
        machine.send_key("ctrl-meta_l-up")

        # Please close the launcher
        machine.sleep(1)
        machine.send_key("esc")
        machine.sleep(1)
        machine.send_key("esc")
        machine.sleep(1)
        machine.send_key("esc")
        machine.sleep(1)

    start_all()
    machine.wait_for_unit("multi-user.target")

    with subtest("lomiri starts"):
        machine.wait_for_file("/run/user/1000/wayland-0")
        machine.succeed("pgrep -x .lomiri-wrapped")
        # Startup is presumed complete & graphical when Lomiri starts printing performance diagnostics
        machine.wait_for_console_text("Last frame took")
        machine.sleep(1)
        machine.screenshot("lomiri_launched")

    with subtest("terminal works"):
        machine.send_key("ctrl-alt-t")
        machine.wait_for_text("alice@machine")
        maximise_new_window(machine)
        machine.screenshot("terminal_opens")

        machine.send_chars("check-waylandinfo\n")
        machine.wait_for_file("/tmp/test-wayland.out")
        machine.sleep(1)
        machine.screenshot("wayland-info")
        machine.succeed("ls /tmp/test-wayland-exit-ok")
        machine.copy_from_vm("/tmp/test-wayland.out")

        machine.send_key("alt-f4")

    with subtest("starter menu works"):
        machine.send_key("meta_l-a")
        machine.wait_for_text("Settings")
        machine.screenshot("starter_opens")

        # Just try the terminal again, cus we know that it works
        machine.send_chars("Terminal\n")
        machine.wait_for_text("alice@machine")
        machine.send_key("alt-f4")

    with subtest("system settings open"):
        machine.send_key("meta_l-a")
        machine.wait_for_text("Settings")
        machine.send_chars("System Settings\n")
        machine.wait_for_text("Rotation Lock")
        maximise_new_window(machine)
        machine.sleep(1)
        machine.screenshot("settings_open")

        # advance focus onto rotation lock toggle for start of sub-page checks
        machine.send_key("tab")
        machine.send_key("tab")
        machine.sleep(1)
        machine.screenshot("settings_open_focus")

    # tab through & open all sub-menus, to make sure none of them crash
  '' + (lib.strings.concatMapStringsSep "\n" (page: ''
    with subtest("system settings ${page.name} works"):
        machine.send_key("tab")
        machine.send_key("kp_enter")
        machine.wait_for_text("${page.element}")
        machine.screenshot("settings_${page.name}")
  '') settingsPages) + ''

    machine.send_key("alt-f4")

    with subtest("morph browser works"):
        machine.send_key("meta_l-a")
        machine.wait_for_text("Morph")
        machine.send_chars("Morph\n")
        machine.wait_for_text("Bookmarks")
        maximise_new_window(machine)
        machine.sleep(1)
        machine.screenshot("morph_open")

        machine.send_chars("file://${pkgs.valgrind.doc}/share/doc/valgrind/html/index.html\n")
        machine.wait_for_text("Valgrind")
        machine.screenshot("morph_htmlcontent")

        machine.send_key("alt-f4")

    # the indicators, especially session control for being able to log out, would be important to test here
    # but afaict this requires mouse control to reach, and ydotool lacks a module for its daemon
    # https://github.com/NixOS/nixpkgs/issues/183659
  '';
})
