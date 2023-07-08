{ fetchurl, qutebrowser, stdenv, undmg }:

if stdenv.hostPlatform.isDarwin then
  stdenv.mkDerivation
  rec {
    pname = "qutebrowser";
    inherit (qutebrowser) version;
    sourceRoot = "qutebrowser.app";
    src = fetchurl {
      url = assert version == "2.5.4";
        # TODO: remove this downgrade after a newer version is available
        let version = "2.5.3"; in
        "https://github.com/qutebrowser/qutebrowser/releases/download/v${version}/qutebrowser-${version}.dmg";
      sha256 = "T3DMZhIuXxI1tDCEi7knu6lscGCVSjU1UW76SaKd1N4=";
    };
    buildInputs = [ undmg ];
    installPhase = ''
      mkdir -p $out/Applications/qutebrowser.app
      cp -R . $out/Applications/qutebrowser.app
      chmod +x $out/Applications/qutebrowser.app/Contents/MacOS/qutebrowser
      mkdir $out/bin
      ln -s $out/Applications/qutebrowser.app/Contents/MacOS/qutebrowser $out/bin/qutebrowser
    '';
  } else qutebrowser
