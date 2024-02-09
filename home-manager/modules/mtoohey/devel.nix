{ nix-index-database, uncommitted-rs, config, lib, pkgs, ... }:

{
  options.mtoohey.devel.enable = lib.mkEnableOption "devel";

  config = lib.mkIf config.mtoohey.devel.enable {
    nixpkgs.overlays = [
      uncommitted-rs.overlays.default
    ];

    home.packages = with pkgs; [
      nil
      nix-index
      pkgs.uncommitted-rs
      watchexec
    ];

    home.file.".cache/nix-index/files".source = lib.mkIf
      (nix-index-database.legacyPackages ? ${pkgs.system})
      nix-index-database.legacyPackages.${pkgs.system}.database;

    programs = {
      bash.enable = true;
      git.lfs.enable = true;
      zsh.enable = true;
    };

    xdg.configFile."gdb/gdbinit".text = ''
      set auto-load safe-path ${config.home.homeDirectory}/repos
    '';
  };
}
