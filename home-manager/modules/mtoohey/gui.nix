{ firefox-addons, config, lib, pkgs, ... }:

{
  options.mtoohey.gui.enable = lib.mkEnableOption "gui";

  config = lib.mkIf config.mtoohey.gui.enable {
    home.packages = with pkgs; [
      ghostty
      ibm-plex
      nerd-fonts.jetbrains-mono
      socat
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      nsxiv
      xdg-utils
    ];

    fonts.fontconfig.enable = true;

    home.file = {
      Downloads.source =
        config.lib.file.mkOutOfStoreSymlink config.home.homeDirectory;
      Pictures.source =
        config.lib.file.mkOutOfStoreSymlink config.home.homeDirectory;
    };
    xdg = {
      configFile = {
        "fontconfig/fonts.conf" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux
          { source = ./gui/fonts.conf; };
        "ghostty/config".text = ''
          font-feature = -dlig
          adjust-cursor-thickness = 3
          theme = Gruvbox Dark
          window-decoration = false
          window-padding-balance = true
          window-padding-x = 8,8
          window-padding-y = 8,8
          resize-overlay = never
          clipboard-read = allow
          copy-on-select = false
          confirm-close-surface = false
        '';
      };
      mimeApps = {
        enable = true;
        defaultApplications = {
          "application/pdf" = "org.pwmt.zathura.desktop";
          "image/jpeg" = "nsxiv.desktop";
          "image/png" = "nsxiv.desktop";
          "image/x-portable-pixmap" = "nsxiv.desktop";
          "text/html" = "firefox.desktop";
          "x-scheme-handler/http" = "firefox.desktop";
          "x-scheme-handler/https" = "firefox.desktop";
        };
      };
    };

    nixpkgs.overlays = [ firefox-addons.overlays.default ];

    programs = {
      brave.enable = true;
      firefox = {
        enable = true;
        profiles.default = {
          extensions.packages =
            let
              inherit (pkgs.stdenv.hostPlatform) system;
              inherit (firefox-addons.lib.${system}) buildFirefoxXpiAddon;
              inherit (pkgs.firefox-addons) bitwarden don-t-fuck-with-paste
                furiganaize gruvbox-dark-theme h264ify multi-account-containers
                temporary-containers youtube-recommended-videos;
              yomitan = buildFirefoxXpiAddon {
                pname = "yomitan";
                version = "24.4.16.0";
                addonId = "{2d13e145-294e-4ead-9bce-b4644b203a00}";
                url = "https://github.com/themoeway/yomitan/releases/download/24.4.16.0/yomitan-firefox-dev.xpi";
                sha256 = "uJzADQ2ToRa2OsnB8qmjRMI5ePBsHdPVPl88dn1aKPQ=";
                meta = { };
              };
            in
            [
              bitwarden
              don-t-fuck-with-paste
              furiganaize
              gruvbox-dark-theme
              h264ify
              multi-account-containers
              # NOTE: manually enable "Automatic Mode"
              temporary-containers
              # NOTE: manually install JMDict dictionary from
              # https://github.com/MarvNC/jmdict-yomitan/releases/latest/download/JMdict_english_with_examples.zip
              # and disable startup notification
              yomitan
              youtube-recommended-videos
            ];
          search = {
            default = "ddg";
            engines = {
              "ddg".urls = [{ template = "https://noai.duckduckgo.com/?q={searchTerms}"; }];
              "Amazon.ca".metaData.hidden = true;
              "bing".metaData.hidden = true;
              "ebay".metaData.hidden = true;
              "google".metaData.hidden = true;
              "wikipedia".metaData.hidden = true;
            };
            force = true;
            order = [ "ddg" ];
          };
          settings = {
            "app.shield.optoutstudies.enabled" = false;
            "browser.aboutConfig.showWarning" = false;
            "browser.bookmarks.file" = builtins.toFile "firefox-bookmarks.html" ''
              <!DOCTYPE NETSCAPE-Bookmark-file-1>
              <meta HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
              <title>Bookmarks</title>
              <h1>Bookmarks Menu</h1>
              <dl><p></p></dl>
            '';
            "browser.newtabpage.enabled" = false;
            "browser.newtabpage.extensionControlled" = true;
            "browser.places.importBookmarksHTML" = true;
            "browser.startup.page" = 3;
            "browser.startup.homepage" = "chrome://browser/content/blanktab.html";
            "browser.tabs.firefox-view" = false;
            "browser.toolbars.bookmarks.visibility" = "never";
            "browser.uiCustomization.state" = /* json */ ''
              {
                "placements": {
                  "widget-overflow-fixed-list": [],
                  "unified-extensions-area": [],
                  "nav-bar": [
                    "back-button",
                    "forward-button",
                    "stop-reload-button",
                    "urlbar-container",
                    "downloads-button"
                  ],
                  "toolbar-menubar": [
                    "menubar-items"
                  ],
                  "TabsToolbar": [
                    "firefox-view-button",
                    "tabbrowser-tabs",
                    "new-tab-button",
                    "alltabs-button"
                  ],
                  "PersonalToolbar": [
                    "import-button",
                    "personal-bookmarks"
                  ]
                },
                "seen": [
                  "developer-button"
                ],
                "dirtyAreaCache": [
                  "nav-bar",
                  "PersonalToolbar",
                  "toolbar-menubar",
                  "TabsToolbar"
                ],
                "currentVersion": 19,
                "newElementCount": 4
              }
            '';
            "browser.urlbar.showSearchSuggestionsFirst" = false;
            "datareporting.healthreport.uploadEnabled" = false;
            "extensions.formautofill.addresses.enabled" = false;
            "extensions.formautofill.creditCards.enabled" = false;
            "extensions.pocket.enabled" = false;
            "findbar.highlightAll" = true;
            "font.default.x-western" = "sans-serif";
            "font.name.monospace.x-western" = "JetBrainsMono Nerd Font";
            "font.name.sans-serif.x-western" = "IBM Plex Sans";
            "font.name.serif.x-western" = "IBM Plex Serif";
            "full-screen-api.ignore-widgets" = true;
            "layout.css.prefers-color-scheme.content-override" = 0;
            "media.eme.enabled" = true;
            "network.protocol-handler.external.mailto" = false;
            "signon.rememberSignons" = false;
            "trailhead.firstrun.didSeeAboutWelcome" = true;
          };
        };
      };
      fish.functions.ssh = {
        # this is necessary because if $TERM gets inherited but the host we're
        # ssh'ing into doesn't have terminfo for xterm-ghostty (which is common)
        # then things go very badly
        body = ''
          if test "$TERM" = "xterm-ghostty"
            TERM=xterm-256color command ssh $argv
          else
            command ssh $argv
          end
        '';
        wraps = "ssh";
      };
      lf.keybindings.gC = "&${pkgs.ghostty}/bin/ghostty -e env SHLVL=0 fish -C lfcd &>/dev/null &";
      mpv = {
        enable = true;
        config = {
          osc = false;
          script-opts-add = "osc-visibility=always";
          osd-font = "JetBrainsMono Nerd Font";
          ytdl-format = "ytdl-format=bestvideo[height<=1440]+bestaudio/best[height<=1440]";
          input-default-bindings = false;
        };
        bindings = {
          SPACE = "cycle pause";

          LEFT = "seek -5";
          DOWN = "add volume -2";
          UP = "add volume 2";
          RIGHT = "seek 5";

          h = "seek -5";
          j = "add volume -2";
          k = "add volume 2";
          l = "seek 5";

          WHEEL_DOWN = "add volume -2";
          WHEEL_UP = "add volume 2";

          "(" = "add speed -0.25";
          ")" = "add speed +0.25";
          "<" = "add sub-delay -0.25";
          ">" = "add sub-delay +0.25";
          "-" = "add video-zoom -0.1";
          "+" = "add video-zoom +0.1";

          n = "playlist-next";
          N = "playlist-prev";

          g = "seek 0 absolute-percent";
          "0" = "seek 0 absolute-percent";
          "1" = "seek 10 absolute-percent";
          "2" = "seek 20 absolute-percent";
          "3" = "seek 30 absolute-percent";
          "4" = "seek 40 absolute-percent";
          "5" = "seek 50 absolute-percent";
          "6" = "seek 60 absolute-percent";
          "7" = "seek 70 absolute-percent";
          "8" = "seek 80 absolute-percent";
          "9" = "seek 90 absolute-percent";
          G = "seek 100 absolute-percent";

          L = ''cycle-values loop-file "inf" "no"'';
          f = "cycle fullscreen";
          a = "cycle audio";
          c = "cycle sub";
          ":" = "cycle osc";

          q = "quit";
        };
      };
      zathura = {
        enable = true;
        extraConfig = "unmap r";
        options = with import ../../themes/gruvbox.nix; {
          guioptions = "";
          adjust-open = "width";
          font = "JetBrainsMono Nerd Font 12";
          selection-clipboard = "clipboard";
          # leaving sandbox enabled prevents links from being opened properly
          # in a browser; see https://tex.stackexchange.com/questions/564989
          sandbox = "none";

          # https://github.com/eastack/zathura-gruvbox/blob/0b49904fe77e6eb676a6318c1acb03afeb2965bb/zathura-gruvbox-dark
          notification-error-bg = "#${bg}";
          notification-error-fg = "#${bright_red}";
          notification-warning-bg = "#${bg}";
          notification-warning-fg = "#${bright_yellow}";
          notification-bg = "#${bg}";
          notification-fg = "#${bright_green}";

          completion-bg = "#${bg2}";
          completion-fg = "#${fg}";
          completion-group-bg = "#${bg1}";
          completion-group-fg = "#${gray}";
          completion-highlight-bg = "#${bright_blue}";
          completion-highlight-fg = "#${bg2}";

          index-bg = "#${bg2}";
          index-fg = "#${fg}";
          index-active-bg = "#${bright_blue}";
          index-active-fg = "#${bg2}";

          inputbar-bg = "#${bg}";
          inputbar-fg = "#${fg}";

          statusbar-bg = "#${bg2}";
          statusbar-fg = "#${fg}";

          highlight-color = "#${bright_yellow}";
          highlight-active-color = "#${bright_orange}";

          default-bg = "#${bg}";
          default-fg = "#${fg}";
          render-loading = true;
          render-loading-bg = "#${bg}";
          render-loading-fg = "#${fg}";

          recolor-lightcolor = "#${bg}";
          recolor-darkcolor = "#${fg}";
        };
      };
    };
  };
}
