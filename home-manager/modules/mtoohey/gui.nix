{ firefox-addons, lf-exa-icons, qbpm, config, lib, pkgs, ... }:

{
  options.mtoohey.gui.enable = lib.mkEnableOption "gui";

  config = lib.mkIf config.mtoohey.gui.enable {
    nixpkgs.overlays = [
      lf-exa-icons.overlays.default
      (final: _: {
        qbpm = qbpm.packages.${final.system}.default;
      })
    ];

    home.packages = with pkgs; [
      ibm-plex
      (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
      pkgs.qbpm
      socat
    ] ++ lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      nsxiv
      xdg-utils
    ];

    fonts.fontconfig.enable = true;

    home.file.Downloads.source = config.lib.file.mkOutOfStoreSymlink config.home.homeDirectory;
    xdg = {
      configFile."fontconfig/fonts.conf" = lib.mkIf
        pkgs.stdenv.hostPlatform.isLinux
        { source = ./gui/fonts.conf; };
      dataFile =
        let
          qutebrowserPrefix =
            if pkgs.stdenv.hostPlatform.isDarwin
            then "${config.home.homeDirectory}/.qutebrowser"
            else "${config.xdg.configHome}/qutebrowser";
        in
        builtins.foldl'
          (s: name: s // {
            "qutebrowser-profiles/${name}/config/config.py".text = ''
              config.load_autoconfig(False);
              config.source('${qutebrowserPrefix}/config.py')
            '';
            "qutebrowser-profiles/${name}/config/greasemonkey".source =
              config.lib.file.mkOutOfStoreSymlink
                "${qutebrowserPrefix}/greasemonkey";
          })
          { } [ "personal" "gaming" "university" ];
      desktopEntries = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
        qbpm = {
          type = "Application";
          name = "qbpm";
          icon = "qutebrowser";
          exec = "qbpm choose -m ${pkgs.fuzzel}/bin/fuzzel";
          categories = [ "Network" ];
          terminal = false;
        };
      };
      mimeApps = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
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

    programs = {
      brave.enable = true;
      firefox = {
        enable = !pkgs.stdenv.hostPlatform.isDarwin;
        profiles.default = {
          extensions =
            let
              inherit (pkgs.stdenv.hostPlatform) system;
              inherit (firefox-addons.lib.${system}) buildFirefoxXpiAddon;
              inherit (firefox-addons.packages.${system}) bitwarden
                don-t-fuck-with-paste furiganaize gruvbox-dark-theme h264ify
                multi-account-containers temporary-containers;
              yomichan = buildFirefoxXpiAddon {
                pname = "yomichan";
                version = "22.10.23.0";
                addonId = "alex.testing@foosoft.net";
                url = "https://github.com/FooSoft/yomichan/releases/download/22.10.23.0/a708116f79104891acbd-22.10.23.0.xpi";
                sha256 = "lSGJcgZcZE9bWcAtUeQZ4SyXv5wdbYDLvOFImjvnFa4=";
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
              # https://github.com/FooSoft/yomichan/raw/dictionaries/jmdict_english.zip
              # and disable startup notification
              yomichan
            ];
          search = {
            default = "DuckDuckGo";
            engines = {
              "Amazon.ca".metaData.hidden = true;
              "Bing".metaData.hidden = true;
              "eBay".metaData.hidden = true;
              "Google".metaData.hidden = true;
              "Wikipedia (en)".metaData.hidden = true;
            };
            force = true;
            order = [ "DuckDuckGo" ];
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
            "signon.rememberSignons" = false;
            "trailhead.firstrun.didSeeAboutWelcome" = true;
          };
        };
      };
      fish.functions.ssh = {
        # this is necessary because if $TERM gets inherited but the host we're
        # ssh'ing into doesn't have terminfo for xterm-kitty (which is common)
        # then things go very badly
        body = ''
          if test "$TERM" = "xterm-kitty"
            TERM=xterm-256color command ssh $argv
          else
            command ssh $argv
          end
        '';
        wraps = "ssh";
      };
      kitty = {
        enable = true;
        environment.SHLVL = "0";
        settings = {
          allow_remote_control = true;
          confirm_os_window_close = 0;
          cursor = "none";
          cursor_blink_interval = 0;
          cursor_text_color = "background";
          enable_audio_bell = false;
          hide_window_decorations = "titlebar-only";
          macos_option_as_alt = true;
          remember_window_size = false;
          scrollback_lines = 10000;
          touch_scroll_multiplier = 9;
          update_check_interval = 0;
          window_padding_width = 8;
        };
        keybindings =
          let
            kitty-kitten-search = pkgs.fetchFromGitHub {
              owner = "trygveaa";
              repo = "kitty-kitten-search";
              rev = "0760138fad617c5e4159403cbfce8421ccdfe571";
              sha256 = "egisza7V5dWplRYHIYt4bEQdqXa4E7UhibyWJAup8as=";
            };
          in
          {
            "ctrl+shift+f" = "launch --location=hsplit --allow-remote-control kitty +kitten ${kitty-kitten-search}/search.py @active-kitty-window-id";
          };
        extraConfig =
          let
            gruvbox-kitty = builtins.fetchurl {
              url = "https://raw.githubusercontent.com/wdomitrz/kitty-gruvbox-theme/b930abcc3a1cdcc763fb65988f07ee0270710f9c/gruvbox_dark.conf";
              sha256 = "1msaz916a7qrsn4dqcygwynanqqm0mw2cpwf18ab7ljn9xzrdnlp";
            };
          in
          ''
            include ${gruvbox-kitty}
          '' + (if pkgs.stdenv.hostPlatform.isDarwin then ''
            font_family JetBrainsMono Nerd Font Mono Regular
            bold_font JetBrainsMono Nerd Font Mono Bold
            italic_font JetBrainsMono Nerd Font Mono Italic
            bold_italic_font JetBrainsMono Nerd Font Mono Bold Italic

            font_size 16
          '' else ''
            font_family JetBrains Mono Regular Nerd Font Complete
            bold_font JetBrains Mono Bold Nerd Font Complete
            italic_font JetBrains Mono Italic Nerd Font Complete
            bold_italic_font JetBrains Mono Bold Italic Nerd Font Complete

            font_size 12
          '');
      };
      lf.keybindings.gC = "&${pkgs.kitty-window} --cwd current fish -C lfcd &>/dev/null &";
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
          c = "cycle sub";
          ":" = "cycle osc";

          q = "quit";
        };
      };
      qutebrowser = {
        enable = true;
        keyBindings = {
          normal = {
            "D" = "close";
            "so" = "config-source";
            "e" = "edit-url";
            "(" = "jseval --world=main -f ${./gui/qutebrowser/js/slowDown.js}";
            ")" = "jseval --world=main -f ${./gui/qutebrowser/js/speedUp.js}";
            "c-" = "jseval --world=main -f ${./gui/qutebrowser/js/zoomOut.js}";
            "c+" = "jseval --world=main -f ${./gui/qutebrowser/js/zoomIn.js}";
            "<ESC>" = "fake-key <ESC>";
            "<Ctrl-Shift-c>" = "yank selection";
            "v" = "hint all hover";
            "V" = "mode-enter caret";
            "<Ctrl-F>" = "hint --rapid all tab-bg";
            "<Ctrl-e>" = "fake-key <Ctrl-a><Ctrl-c><Ctrl-Shift-e>";
            "o" = "set statusbar.show always;; cmd-set-text -s :open";
            "O" = "set statusbar.show always;; cmd-set-text -s :open -t";
            ":" = "set statusbar.show always;; cmd-set-text :";
            "/" = "set statusbar.show always;; cmd-set-text /";
            "ge" = "scroll-to-perc";
          };
          command = {
            "<Escape>" = "mode-enter normal;; set statusbar.show never";
            "<Return>" = "command-accept;; set statusbar.show never";
          };
        };
        settings =
          let
            command_prefix = [
              "${pkgs.kitty}/bin/kitty"
              "--override"
              "macos_quit_when_last_window_closed=yes"
              "--title"
              "floatme"
              "fish"
              "-c"
            ];
          in
          {
            auto_save.session = true;
            colors.webpage.preferred_color_scheme = "dark";
            completion.height = "25%";
            content = {
              fullscreen.window = true;
              headers.do_not_track = null;
              javascript.clipboard = "access";
            };
            downloads.location = {
              directory = "${config.home.homeDirectory}";
              remember = false;
            };
            editor.command = command_prefix ++ [ "$EDITOR {file}" ];
            fileselect = {
              handler = "external";
              single_file.command = command_prefix ++ [
                ". ${pkgs.lf-exa-icons-output} && lf -command 'map <enter> \${{echo \\\"$f\\\" > {}; lf -remote \\\"send $id quit\\\"}}'"
              ];
              multiple_files.command = command_prefix ++ [
                ". ${pkgs.lf-exa-icons-output} && lf -command 'map <enter> \${{echo \\\"$fx\\\" > {}; lf -remote \\\"send $id quit\\\"}}'"
              ];
              folder.command = command_prefix ++ [
                ". ${pkgs.lf-exa-icons-output} && lf -command 'set dironly; map <enter> \${{echo \\\"$f\\\" > {}; lf -remote \\\"send $id quit\\\"}}'"
              ];
            };
            fonts = {
              default_size = if pkgs.stdenv.hostPlatform.isDarwin then "16pt" else "12pt";
              default_family = "JetBrainsMono Nerd Font";
            };
            fonts.web.family = {
              standard = "IBM Plex Sans";
              sans_serif = "IBM Plex Sans";
              serif = "IBM Plex Serif";
              fixed = "JetBrainsMono Nerd Font";
            };
            hints.chars = "asdfghjkl;qwertyuiopzxcvbnm";
            statusbar.show = "never";
            tabs = {
              background = false;
              last_close = "close";
              show = "switching";
              show_switching_delay = 1500;
              title.format = "{current_title}";
            };
            url = rec {
              default_page =
                let
                  new-tab = ''
                    <!DOCTYPE html>
                    <html>
                      <head>
                        <title>new tab</title>
                      </head>
                      <body style="background: #${(import ../../themes/gruvbox.nix).bg}" />
                    </html>
                  '';
                in
                "file://${builtins.toFile "new-tab.html" new-tab}";
              start_pages = default_page;
            };
          };
        extraConfig =
          let
            gruvbox-qutebrowser = builtins.fetchurl {
              url = "https://raw.githubusercontent.com/The-Compiler/dotfiles/master/qutebrowser/gruvbox.py";
              sha256 = "16v9p81h059mzdvikg4d1dfhbj5v8jqbsgw9yanrpq6cfj7wrx6l";
            };
          in
          ''
            config.unbind('<Ctrl-v>')
            config.unbind('<Ctrl-a>')
            config.source('${gruvbox-qutebrowser}')
            import json
          '' + lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
            c.qt.args = ["single-process"]
          '' + lib.optionalString (config.programs.fish.shellAliases ? "copy") ''
            config.bind('yg', 'spawn --userscript ${pkgs.writeShellScript "qute-yank-git" ''
              set -eo pipefail
              printf "$QUTE_URL" | sed -E 's/^https?:\/\/github.com\//git@github.com:/;s/ (\/[^/]*)\/.*/\1/' | ${config.programs.fish.shellAliases.copy}
            ''}')
          '';
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
