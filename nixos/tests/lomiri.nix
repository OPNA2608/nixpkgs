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
  };

  enableOCR = true;

  testScript = { nodes, ... }: ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    # Wait for Lomiri to complete startup
    machine.wait_for_file("/run/user/1000/wayland-0")
    machine.succeed("pgrep -x lomiri")
    machine.screenshot("lomiri_launched")
  '';
})
