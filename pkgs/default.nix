inputs: pkgs:
let inherit (pkgs) callPackage; in
{
  brave = callPackage ./applications/networking/browsers/brave {
    inherit (pkgs) brave;
  };
  gickup = callPackage ./applications/backup/gickup { };
  kitty = callPackage ./applications/terminal-emulators/kitty {
    inherit (pkgs) kitty;
  };
  kitty-window = callPackage ./applications/terminal-emulators/kitty-window { };
  python3Packages = pkgs.python3Packages.overrideScope (final: _: {
    fugashi = final.buildPythonPackage rec {
      pname = "fugashi";
      version = "1.2.1";

      src = final.fetchPypi {
        inherit pname version;
        sha256 = "58eupmhABq8iO1FFuWwHHC4QNTr7nfZxLfRFgAPPYtM=";
      };

      nativeBuildInputs = [ pkgs.mecab ];

      propagatedBuildInputs = [ final.cython final.setuptools_scm ];
    };
    manga-ocr = final.buildPythonPackage rec {
      pname = "manga-ocr";
      version = "0.1.10";

      src = final.fetchPypi {
        inherit pname version;
        sha256 = "hSJf8bLd9ON9Q8zTqYtOtk1m7SGGKghLrXOYxZdnG8I=";
      };

      propagatedBuildInputs = [
        final.fire
        final.fugashi
        final.jaconv
        final.loguru
        final.numpy
        final.pillow
        final.pyperclip
        final.torch
        final.transformers
        final.unidic-lite
      ];

      postInstall = ''
        cp -r assets $out/lib/python3.10/site-packages/assets
      '';
    };
    mokuro = (final.buildPythonPackage rec {
      pname = "mokuro";
      version = "0.1.7";

      src = final.fetchPypi {
        inherit pname version;
        sha256 = "BE1EyY955UkrhF8cK2NYExAQ8ieXgrlDyaIPGYab8uo=";
      };

      propagatedBuildInputs = [
        final.manga-ocr
        final.opencv4
        final.scipy
        final.pyclipper
        final.yattag
        final.shapely
        final.natsort
        final.torchsummary
        final.torchvision
      ];

      postPatch =
        let
          comictextdetector-model = pkgs.fetchurl {
            url = "https://github.com/zyddnys/manga-image-translator/releases/download/beta-0.2.1/comictextdetector.pt";
            sha256 = "H5D6YK7rHrguKsEWema/E5qKYbh4Cs01Hq1VJoVAzMs=";
          };
          ocr-model = pkgs.fetchgit {
            url = "https://huggingface.co/kha-white/manga-ocr-base";
            rev = "aa6573bd10b0d446cbf622e29c3e084914df9741";
            fetchLFS = true;
            sha256 = "IhB2u2QEikum6mb8f6DT+GwV6RtMjypM6oQn/oIkL8k=";
          };
        in
          /* bash */ ''
          # Fix opencv dependency name.
          substituteInPlace setup.py --replace "opencv-python" "opencv"

          # Make comictextdetector model reproducible.
          substituteInPlace mokuro/manga_page_ocr.py --replace \
            "model_path=cache.comic_text_detector" \
            "model_path='${comictextdetector-model}'"
          substituteInPlace mokuro/manga_page_ocr.py --replace \
            "from mokuro.cache import cache" ""
          rm mokuro/cache.py

          # Make ocr model reproducible.
          for file in mokuro/{manga_page_ocr,run,overlay_generator}.py; do
            substituteInPlace $file --replace \
              "pretrained_model_name_or_path='kha-white/manga-ocr-base'" \
              "pretrained_model_name_or_path='${ocr-model}'"
          done
        '';
    }).overrideAttrs (oldAttrs: {
      setuptoolsCheckPhase = ''
        TRANSFORMERS_CACHE=$tmp
      '' + oldAttrs.setuptoolsCheckPhase or "";
    });
    torchsummary = final.buildPythonPackage rec {
      pname = "torchsummary";
      version = "1.5.1";

      src = final.fetchPypi {
        inherit pname version;
        sha256 = "mBv2ieIuDPf5XHRgAvIKJK0mqmudhhE0oUvGzpIjBZA=";
      };

      propagatedBuildInputs = [ final.torch ];
    };
  });
  qutebrowser = callPackage ./applications/networking/browsers/qutebrowser {
    inherit (pkgs) qutebrowser;
  };
} // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
  Karabiner-DriverKit-VirtualHIDDevice = callPackage
    ./os-specific/darwin/Karabiner-DriverKit-VirtualHIDDevice
    { Karabiner-DriverKit-VirtualHIDDevice-src = inputs.kmonad + "/../c_src/mac/Karabiner-DriverKit-VirtualHIDDevice"; };
  kmonad-daemon-shim = callPackage ./os-specific/darwin/kmonad-daemon-shim { };
  yabai = callPackage ./os-specific/darwin/yabai {
    inherit (pkgs) yabai;
  };
}
