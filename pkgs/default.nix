inputs: pkgs:
let inherit (pkgs) callPackage; in
{
  gickup = callPackage ./applications/backup/gickup { };
  kitty = callPackage ./applications/terminal-emulators/kitty {
    inherit (pkgs) kitty;
  };
} // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
  Karabiner-DriverKit-VirtualHIDDevice = callPackage
    ./os-specific/darwin/Karabiner-DriverKit-VirtualHIDDevice
    { Karabiner-DriverKit-VirtualHIDDevice-src = inputs.kmonad + "/c_src/mac/Karabiner-DriverKit-VirtualHIDDevice"; };
  kmonad-daemon-shim = callPackage ./os-specific/darwin/kmonad-daemon-shim { };
  yabai = callPackage ./os-specific/darwin/yabai {
    inherit (pkgs) yabai;
  };
}
