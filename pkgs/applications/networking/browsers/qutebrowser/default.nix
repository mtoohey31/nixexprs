{ fetchurl, qutebrowser, stdenv, undmg }:

if stdenv.hostPlatform.isDarwin then
  stdenv.mkDerivation
  rec {
    pname = "qutebrowser";
    inherit (qutebrowser) version;
    sourceRoot = "qutebrowser.app";
    src = fetchurl {
      url = "https://github.com/qutebrowser/qutebrowser/releases/download/v${version}/qutebrowser-${version}.dmg";
      sha256 = "A6dxf1dRpku+qUhUnXwRzta8uBx8JpwK4Lvh10sy9dQ=";
    };
    buildInputs = [ undmg ];
    dontFixup = true;
    installPhase = ''
      mkdir -p $out/Applications/qutebrowser.app
      cp -R . $out/Applications/qutebrowser.app
      chmod +x $out/Applications/qutebrowser.app/Contents/MacOS/qutebrowser
      mkdir $out/bin
      ln -s $out/Applications/qutebrowser.app/Contents/MacOS/qutebrowser $out/bin/qutebrowser
    '';
  } else qutebrowser
