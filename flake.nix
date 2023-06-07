{
  description = "nixexprs";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";

    kmonad = {
      url = "git+https://github.com/kmonad/kmonad?submodules=1&dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, utils, ... }@inputs: {
    lib = import ./lib nixpkgs.lib;

    darwinModules = { }; # TODO
    homeManagerModules = { }; # TODO
    nixOnDroidModules = { }; # TODO
    nixosModules = { }; # TODO

    overlays.default = _: prev: let pkgs = prev; in import ./pkgs inputs pkgs;
  } // utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        overlays = builtins.attrValues self.overlays;
        inherit system;
      };
      inherit (pkgs) deadnix gnumake graphviz mkShell nil nix-du nixpkgs-fmt
        statix;
    in
    {
      devShells.default = mkShell {
        packages = [ deadnix gnumake graphviz nil nix-du nixpkgs-fmt statix ];
      };

      packages = self.lib.filterSupportedPackages system
        (import ./pkgs inputs (import nixpkgs { inherit system; }));
    });
}
