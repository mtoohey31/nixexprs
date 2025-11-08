pkgs:
let inherit (pkgs) callPackage; in
pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
  yabai = callPackage ./os-specific/darwin/yabai {
    inherit (pkgs) yabai;
  };
}
