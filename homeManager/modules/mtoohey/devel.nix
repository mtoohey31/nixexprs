{ nix-index-database, uncommitted-rs, config, lib, pkgs, ... }:

{
  options.mtoohey.devel.enable = lib.mkEnableOption "devel";

  config = lib.mkIf config.mtoohey.devel.enable {
    home.packages = with pkgs; [
      nil
      nix-index
      # TODO: introduce this using an overlay instead
      uncommitted-rs.packages.${pkgs.system}.default
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
  };
}
