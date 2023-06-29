{ config, lib, pkgs, ... }:

let cfg = config.mtoohey.primary-user; in
{
  options.mtoohey.primary-user = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    username = lib.mkOption {
      type = lib.types.str;
    };

    homeManagerCfg = lib.mkOption {
      type = lib.types.nullOr (lib.types.functionTo lib.types.attrs);
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    users = {
      users.${cfg.username} = {
        home = "/Users/${cfg.username}";
        createHome = true;
        shell = pkgs.fish;
      };
    };

    home-manager = lib.mkIf (cfg.homeManagerCfg != null) {
      users.${cfg.username} = cfg.homeManagerCfg;
      useUserPackages = true;
    };

    system.activationScripts.users.text = ''
      if [ "$(dscl . -read /Users/${cfg.username} UserShell)" != 'UserShell: ${pkgs.fish}/bin/fish' ]; then
          dscl . -create '/Users/${cfg.username}' UserShell '${pkgs.fish}/bin/fish'
      fi
    '';
  };
}
