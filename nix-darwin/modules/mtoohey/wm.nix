{ nixexprs, config, lib, pkgs, ... }:

{
  options.mtoohey.wm.enable = lib.mkEnableOption "wm";

  config = lib.mkIf config.mtoohey.wm.enable {
    nixpkgs.overlays = [ nixexprs.overlays.default ];

    launchd.user.agents.skhd.serviceConfig.EnvironmentVariables.SHELL = "${pkgs.bash}/bin/bash";

    services = {
      skhd = {
        enable = true;
        skhdConfig = ''
          cmd - h : yabai -m window --focus west || yabai -m display --focus west
          cmd - j : yabai -m window --focus south || yabai -m display --focus south
          cmd - k : yabai -m window --focus north || yabai -m display --focus north
          cmd - l : yabai -m window --focus east || yabai -m display --focus east

          cmd + shift - h : yabai -m window --swap west || (yabai -m display --focus west && sleep 0.1 && yabai -m window --swap recent && yabai -m window --focus recent)
          cmd + shift - j : yabai -m window --swap south || (yabai -m display --focus south && sleep 0.1 && yabai -m window --swap recent && yabai -m window --focus recent)
          cmd + shift - k : yabai -m window --swap north || (yabai -m display --focus north && sleep 0.1 && yabai -m window --swap recent && yabai -m window --focus recent)
          cmd + shift - l : yabai -m window --swap east || (yabai -m display --focus east && sleep 0.1 && yabai -m window --swap recent && yabai -m window --focus recent)

          cmd + shift - tab : yabai -m window --toggle float
          cmd - return : ${pkgs.ghostty}/bin/ghostty

          cmd + shift - b : yabai -m space --balance
          cmd + shift - y : launchctl kickstart -k gui/501/org.nixos.yabai

          cmd - 0x2C : ${pkgs.ghostty}/bin/ghostty -e fish -C lf
          cmd + shift - 0x2C : open ~
        '';
      };

      yabai = {
        enable = true;
        config = {
          mouse_follows_focus = "on";
          focus_follows_mouse = "autoraise";
          window_topmost = "on";
          window_shadow = "float";
          mouse_modifier = "cmd";
          mouse_action1 = "move";
          mouse_action2 = "resize";
          mouse_drop_action = "swap";
          layout = "bsp";
          window_gap = 16;
        };
        package = pkgs.yabai;
      };
    };
  };
}
