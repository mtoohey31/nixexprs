{ nixpkgs, config, lib, pkgs, ... }:

{
  options.mtoohey.common.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };

  config = lib.mkIf config.mtoohey.common.enable {
    nix = import ../../../common/nix-config.nix { inherit nixpkgs pkgs; };

    programs.fish.enable = true;
    services.nix-daemon.enable = true;

    system.defaults = {
      NSGlobalDomain = {
        AppleInterfaceStyleSwitchesAutomatically = true;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSDocumentSaveNewDocumentsToCloud = false;
        _HIHideMenuBar = true;
      };
      dock = {
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.25;
        mru-spaces = false;
        show-recents = false;
        static-only = true;
      };
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        CreateDesktop = false;
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "clmv";
        ShowPathbar = true;
      };
      loginwindow.GuestEnabled = false;
      trackpad = {
        Clicking = true;
        Dragging = true;
        TrackpadThreeFingerDrag = true;
      };
    };
  };
}
