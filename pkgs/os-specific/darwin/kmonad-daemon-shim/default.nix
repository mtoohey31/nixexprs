{ Karabiner-DriverKit-VirtualHIDDevice, stdenv }:

stdenv.mkDerivation {
  pname = "kmonad-daemon-shim";
  version = "0.1.0";
  src = ./.;
  patchPhase = ''
    substituteInPlace main.c \
      --subst-var-by client "${Karabiner-DriverKit-VirtualHIDDevice}/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-DriverKit-VirtualHIDDeviceClient.app/Contents/MacOS/Karabiner-DriverKit-VirtualHIDDeviceClient"
  '';
  buildPhase = ''
    cc main.c -o kmonad-daemon-shim
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp kmonad-daemon-shim $out/bin
  '';
}
