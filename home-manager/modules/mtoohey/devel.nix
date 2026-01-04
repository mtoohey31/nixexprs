{ config, lib, pkgs, ... }:

{
  options.mtoohey.devel.enable = lib.mkEnableOption "devel";

  config = lib.mkIf config.mtoohey.devel.enable {
    nixpkgs.overlays = [ ];

    home.packages = with pkgs; [ nil vscodium watchexec ];

    programs = {
      bash.enable = true;
      git.lfs.enable = true;
      nix-index-database.comma.enable = true;
      zsh.enable = true;
    };

    xdg.configFile."gdb/gdbinit".text = ''
      set auto-load safe-path ${config.home.homeDirectory}/repos
    '';
  };
}
