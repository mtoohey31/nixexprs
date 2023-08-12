{ brave, fetchurl, stdenv, undmg }:

if stdenv.hostPlatform.isDarwin then
  stdenv.mkDerivation
  rec {
    pname = "brave";
    inherit (brave) version;
    sourceRoot = "Brave Browser.app";
    src = fetchurl {
      url = "https://github.com/brave/brave-browser/releases/download/v${version}/Brave-Browser-x64.dmg";
      sha256 = "6pDDla8o5TU3YUov0g4ujNWcIEx8J9z2IsvghKQXcR8=";
    };
    buildInputs = [ undmg ];
    installPhase = ''
      mkdir -p $out/Applications/Brave\ Browser.app
      cp -R . $out/Applications/Brave\ Browser.app
    '';
  } else brave
