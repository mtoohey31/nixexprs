{ nixpkgs, pkgs, ... }:

{
  extraOptions = ''
    experimental-features = nix-command flakes
    keep-outputs = true
  '';
  gc = {
    automatic = true;
    options = "--delete-older-than 14d";
  };
  nixPath = [ "nixpkgs=${nixpkgs}" ];
  package = pkgs.nixFlakes;
  registry.nixpkgs = {
    from = {
      type = "indirect";
      id = "nixpkgs";
    };
    to = {
      type = "path";
      path = nixpkgs;
    };
  };
}
