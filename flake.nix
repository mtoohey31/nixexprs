{
  description = "nixexprs";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ghostty = {
      url = "github:ghostty-org/ghostty";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "utils";
      };
    };
    helix = {
      url = "github:mtoohey31/helix/lean.hx";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lean-hx = {
      url = "git+https://github.com/mtoohey31/lean.hx?submodules=1";
      flake = false;
    };
    mattwparas-helix-config = {
      url = "github:mattwparas/helix-config";
      flake = false;
    };
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    squish = {
      url = "github:mtoohey31/squish?dir=nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "utils";
      };
    };
    tree-sitter-ott = {
      url = "github:armonjam/tree-sitter-ott";
      flake = false;
    };
    uncommitted-rs = {
      url = "github:mtoohey31/uncommitted-rs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        utils.follows = "utils";
      };
    };
    vimv2 = {
      url = "github:mtoohey31/vimv2";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        utils.follows = "utils";
      };
    };
  };

  outputs =
    { self
    , nixpkgs
    , utils
    , nix-index-database
    , pre-commit-hooks
    , ...
    }@inputs:
    {
      lib = import ./lib nixpkgs.lib // {
        pre-commit-hooks = {
          deadnix.enable = true;
          nil.enable = true;
          nixpkgs-fmt = {
            enable = true;
            args = [ "--check" ];
          };
          statix = {
            enable = true;
            settings.config = ".statix.toml";
          };
        };
      };

      darwinModules = self.lib.callModules {
        moduleListPath = ./nix-darwin/modules/module-list.nix;
        inherit inputs;
        selfName = "nixexprs";
      };
      homeManagerModules = {
        inherit (nix-index-database.hmModules) nix-index;
      } // self.lib.callModules {
        moduleListPath = ./home-manager/modules/module-list.nix;
        inherit inputs;
        selfName = "nixexprs";
      };

      overlays.default = _: prev: let pkgs = prev; in import ./pkgs inputs pkgs;
    } // utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          overlays = builtins.attrValues self.overlays;
          inherit system;
        };
        inherit (pkgs) gnumake mkShell nil;
      in
      rec {
        checks.pre-commit = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = self.lib.pre-commit-hooks;
        };

        devShells.default = mkShell {
          inherit (checks.pre-commit) shellHook;
          packages = [ gnumake nil ];
        };

        packages = self.lib.filterSupportedPackages system (
          import ./pkgs inputs (import nixpkgs { inherit system; })
        );
      }
    );
}
