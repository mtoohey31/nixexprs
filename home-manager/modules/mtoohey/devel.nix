{ uncommitted-rs, config, lib, pkgs, ... }:

{
  options.mtoohey.devel.enable = lib.mkEnableOption "devel";

  config = lib.mkIf config.mtoohey.devel.enable
    {
      nixpkgs.overlays = [ uncommitted-rs.overlays.default ];

      home.packages = with pkgs; [ nil pkgs.uncommitted-rs watchexec ];

      programs = {
        bash.enable = true;
        git.lfs.enable = true;
        zsh.enable = true;
      };

      xdg.configFile."gdb/gdbinit".text = ''
        set auto-load safe-path ${config.home.homeDirectory}/repos
      '';
    } // { nix-index-database.comma.enable = config.mtoohey.devel.enable; };
}
