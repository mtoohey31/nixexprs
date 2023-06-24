{ brave, fetchurl, stdenv, undmg }:

if stdenv.hostPlatform.isDarwin then
  stdenv.mkDerivation
  rec {
    pname = "brave";
    inherit (brave) version;
    sourceRoot = "Brave Browser.app";
    src = fetchurl {
      url = "https://github.com/brave/brave-browser/releases/download/v${version}/Brave-Browser-x64.dmg";
      sha256 = "Fuc1YtfbQKaoqMDhyDaDITrJ4pMqA+857L2rgBtX9O0=";
    };
    buildInputs = [ undmg ];
    installPhase = ''
      mkdir -p $out/Applications/Brave\ Browser.app
      cp -R . $out/Applications/Brave\ Browser.app
    '';
  } else brave
