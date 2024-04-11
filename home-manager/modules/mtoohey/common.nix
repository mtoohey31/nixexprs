{ helix, nixexprs, vimv2, config, lib, pkgs, ... }:

let cfg = config.mtoohey.common; in
{
  options.mtoohey.common = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    helix-overlay = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf config.mtoohey.common.enable {
    home.stateVersion = "20.09";

    nixpkgs.overlays = lib.optionals cfg.helix-overlay [
      helix.overlays.default
      (_: prev:
        let inherit (prev) helix; in {
          helix = helix.passthru.wrapper (helix.unwrapped.overrideAttrs
            (oldAttrs: {
              patches = (oldAttrs.patches or [ ]) ++ [
                ./common/only-move-vertically-visually-without-count.patch
              ];
            }));
        })
    ] ++ [
      nixexprs.overlays.default
      vimv2.overlays.default
    ];

    home.packages = with pkgs; [
      archiver
      comma
      eza
      fd
      jq
      ripgrep
      trash-cli
      pkgs.vimv2
      wget
    ];

    home.file.".hushlogin" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin { text = ""; };

    xdg.configFile."lf/cleaner" = {
      text = ''
        #!${pkgs.bash}/bin/sh
        kitten icat --transfer-mode file --stdin no --clear </dev/null >/dev/tty
      '';
      executable = true;
    };

    # TODO: figure out how to set $NIX_PATH in here too so that home-manager
    # only consumers still get the in-path nixpkgs version locked to the version
    # used for their home config

    nix.package = lib.mkDefault pkgs.nixFlakes;

    home.sessionVariables = {
      DIRENV_LOG_FORMAT = "";
      GOPATH = "${config.home.homeDirectory}/.go";
      LESS = "-Ri --incsearch";
      LS_COLORS = "";
      SHELL = "${pkgs.fish}/bin/fish";
    };
    programs =
      let
        # source: https://github.com/andreafrancia/trash-cli/issues/107#issuecomment-479241828
        trash-undo = "echo '' | trash-restore 2>/dev/null | sed '$d' | sort -k2,3 -k1,1n | awk 'END {print $1}' | trash-restore >/dev/null 2>&1";
      in
      {
        bash = {
          inherit (config.programs.fish) shellAliases;
        } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          enableCompletion = false;
          shellOptions = [
            "histappend"
            "checkwinsize"
            "extglob"
          ];
        };
        bat = {
          enable = true;
          config = { style = "plain"; theme = "gruvbox-dark"; };
        };
        bottom.enable = true;
        direnv = {
          enable = true;
          config = {
            disable_stdin = true;
            warn_timeout = "11037h";
          };
          nix-direnv.enable = true;
        };
        fish = rec {
          enable = true;
          shellAbbrs = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin
            {
              copy = "pbcopy";
              paste = "pbpaste";
            } // {
            c = "command";
            da = "direnv allow";
            dn = "direnv deny";
            dr = "direnv reload";
            dx = "echo /.envrc >> .git/info/exclude";
            g = "git";
            pcp = "rsync -r --info=progress2";
            rm = "trash";
            uf = "echo use flake >> .envrc && direnv allow";
            ufi = "echo use flake \\~/repos/infra# >> .envrc && direnv allow";
          };
          shellAliases = shellAbbrs // {
            inherit trash-undo;
            ls = "eza -a --icons --group-directories-first";
            lsd = "eza -al --icons --group-directories-first";
            lst = "eza -aT -L 5 --icons --group-directories-first";
            lsta = "eza -aT --icons --group-directories-first";
          };
          functions = {
            lfcd = {
              body = ''
                set tmp (mktemp)
                lf -last-dir-path=$tmp $argv
                if test -f "$tmp"
                    set dir (cat $tmp)
                    command rm -f $tmp
                    if test -d "$dir"
                        cd $dir
                    end
                end
              '';
              wraps = "lf";
            };
            mv = {
              body = ''
                if test (count $argv) -ge 2 -a ! -d "$argv[-1]" -a -e "$argv[-1]"
                    trash "$argv[-1]"
                end
                command mv $argv
              '';
              wraps = "mv";
            };
          };
          shellInit =
            let
              batmanPager = pkgs.writeShellScript "bat-manpager" "col -bx | bat -l man";
            in
            ''
              export EDITOR=hx
              export VISUAL=hx
              export PAGER=bat
              export MANPAGER=${batmanPager}
              export MANROFFOPT="-c"

              if test -z "$COLORTERM" && string match '*-256color' "$TERM" >/dev/null
                export COLORTERM=truecolor
              end
            '';
          loginShellInit =
            let
              gruvbox-palette = builtins.fetchurl {
                # https://github.com/morhetz/gruvbox/pull/416
                url = "https://raw.githubusercontent.com/morhetz/gruvbox/ca12bc7116dc400d719398e2e4b94bbfcefc1cc7/gruvbox_256palette.fish";
                sha256 = "1rl7zp2jap866qmbcqvl7vswn54pg83q5gafqb921g9vb1zsa3dj";
              };
            in
            ''
              if test -z "$DISPLAY" -a -z "$WAYLAND_DISPLAY" -a -z "$TMUX" -a -n "$SSH_CONNECTION"
                source ${gruvbox-palette}

                exec tmux
              end
            '';
          interactiveShellInit = let stty = if pkgs.stdenv.hostPlatform.isDarwin then "/bin/stty" else "stty"; in ''
            fish_vi_key_bindings

            bind -s -M visual e forward-single-char forward-word backward-char
            bind -s -M visual E forward-bigword backward-char

            bind -s -M insert \cf 'set old_tty (${stty} -g); ${stty} sane; lfcd; ${stty} $old_tty; commandline -f repaint'
            bind -s -M insert \cl '${if pkgs.stdenv.hostPlatform.isDarwin then "/usr/bin/tput reset" else "tput reset"}; if test -n "$TMUX"; tmux clear-history; else; printf "\e[5 q"; end; commandline -f repaint'

            set fish_cursor_default block
            set fish_cursor_insert line
            set fish_cursor_replace_one underscore

            set -U fish_color_autosuggestion brblack
            set -U fish_color_cancel -r
            set -U fish_color_command brgreen
            set -U fish_color_comment brmagenta
            set -U fish_color_cwd green
            set -U fish_color_cwd_root red
            set -U fish_color_end brmagenta
            set -U fish_color_error brred
            set -U fish_color_escape brcyan
            set -U fish_color_history_current --bold
            set -U fish_color_host normal
            set -U fish_color_match --background=brblue
            set -U fish_color_normal normal
            set -U fish_color_operator cyan
            set -U fish_color_param brblue
            set -U fish_color_quote yellow
            set -U fish_color_redirection bryellow
            set -U fish_color_search_match bryellow '--background=brblack'
            set -U fish_color_selection white --bold '--background=brblack'
            set -U fish_color_status red
            set -U fish_color_user brgreen
            set -U fish_color_valid_path --underline
            set -U fish_pager_color_completion normal
            set -U fish_pager_color_description yellow
            set -U fish_pager_color_prefix white --bold --underline
            set -U fish_pager_color_progress brwhite '--background=cyan'

            set fish_greeting

            alias e "$EDITOR"
            abbr e "$EDITOR"
            abbr cat bat
          '';
        };
        git = {
          enable = true;
          userName = lib.mkDefault "Matthew Toohey";
          userEmail = lib.mkDefault "contact@mtoohey.com";
          iniContent = {
            advice.detachedHead = false;
            branch.autosetuprebase = "always";
            core.quotePath = false;
            init.defaultBranch = "main";
          };
          aliases = {
            a = "add --verbose";
            aa = "add --all --verbose";
            add = "add --verbose";
            af = "add --force --verbose";
            afhp = "add --force --patch .";
            afp = "add --force --patch";
            ah = "add --verbose .";
            ahp = "add --patch .";
            ap = "add --patch --verbose";
            b = "!git --no-pager branch";
            bb = "!git branch -m $(git rev-parse --abbrev-ref HEAD) $(git rev-parse --abbrev-ref HEAD)-bak";
            bx = "branch --delete";
            bxx = "branch --delete --force";
            br = "!git branch --move $(git rev-parse --abbrev-ref HEAD)";
            bm = "branch --move";
            bs = "branch --set-upstream-to";
            bt = "branch --track";
            bu = "branch --unset-upstream";
            bv = "!git --no-pager branch -vv";
            c = "commit";
            ca = "commit --amend";
            can = "commit --amend --no-edit";
            canp = "!git commit --amend --no-edit && git push";
            cap = "!git commit --amend && git push";
            cd = "reset --hard HEAD~";
            cm = ''!f() { git commit --message "$*"; }; f'';
            cu = "reset HEAD~";
            d = "diff";
            dh = "diff .";
            dl = "diff HEAD~ HEAD";
            dlt = "diff --stat HEAD~ HEAD";
            ds = "diff --staged";
            dst = "diff --staged --stat";
            dt = "diff --stat";
            dw = "diff --no-prefix --unified=99999999999999999";
            e = "rebase";
            ea = "rebase --abort";
            ec = "rebase --continue";
            ei = "rebase --interactive";
            eir = "rebase --interactive --root";
            eirt = "rebase --interactive --root --autostash";
            eit = "rebase --interactive --autostash";
            es = "rebase --skip";
            et = "rebase --autostash";
            f = "fetch";
            fu = "fetch --unshallow";
            g = "reflog";
            i = "init";
            k = "checkout";
            kb = "checkout -b";
            kbf = "checkout -b --force";
            kf = "checkout --force";
            l = "log";
            m = "remote --verbose";
            ma = "remote add";
            mao = "remote add origin";
            mau = "remote add upstream";
            mp = "remote prune";
            mpo = "remote prune origin";
            mr = "remote rename";
            mro = "remote rename origin";
            ms = "remote set-url";
            mso = "remote set-url origin";
            msu = "remote set-url upstream";
            mx = "remote remove";
            o = "clone --recursive";
            ob = "clone --bare";
            onr = "clone";
            p = "push";
            pf = "push --force";
            pu = "!git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)";
            puf = "!git push --force --set-upstream origin $(git rev-parse --abbrev-ref HEAD)";
            r = "restore";
            rh = "restore .";
            rp = "restore --patch";
            rs = "restore --staged";
            rsh = "restore --staged .";
            rsp = "restore --staged --patch .";
            s = "status --short";
            sh = "status --short .";
            ssh = "!git remote set-url origin $(git remote get-url origin | sed -E 's,^https?://([^/]+)/,git@\\1:,')";
            t = "stash push --include-untracked --keep-index";
            td = "stash drop";
            tl = "stash list";
            tp = "stash pop";
            tpp = "stash push --patch";
            ts = "stash show -p";
            tst = "stash show";
            u = "pull";
            unbare = ''!f() { TARGET="$(echo "$1" | sed -E 's/\.git\/?$//')" && mkdir "$TARGET" && cp -r "$1" "$TARGET/.git" && cd "$TARGET" && git config --local --bool core.bare false && git reset --hard; }; f'';
            ur = "pull --rebase";
            urt = "pull --rebase --autostash";
            ut = "pull --autostash";
            v = "revert";
            va = "revert --abort";
            vc = "revert --continue";
            w = "worktree";
            wa = "worktree add";
            wm = "worktree move";
            wp = "worktree prune";
            wx = "worktree remove";
            x = "rm";
            xc = "rm --cached";
            xch = "rm --cached .";
            xrc = "rm -r --cached";
            xrch = "rm -r --cached .";
            y = "cherry-pick";
            ya = "cherry-pick --abort";
            yc = "cherry-pick --continue";
            z = "switch -";
          } // lib.optionalAttrs (config.programs.fish.shellAliases ? "copy") {
            cy = "!git rev-parse HEAD | ${pkgs.gnused}/bin/sed -z 's/\\n$//' | ${config.programs.fish.shellAliases.copy}";
            by = "!git rev-parse --abbrev-ref HEAD | ${pkgs.gnused}/bin/sed -z 's/\\n$//' | ${config.programs.fish.shellAliases.copy}";
          };
        };
        helix = {
          enable = true;
          languages = {
            language =
              let
                helix-src =
                  if cfg.helix-overlay
                  then pkgs.helix.unwrapped.src
                  else pkgs.helix.src;
                langFilename = "${helix-src}/languages.toml";
                langData = builtins.fromTOML (builtins.readFile langFilename);
                defaultFileTypes = language: (lib.lists.findFirst
                  (lang: lang.name == language)
                  (throw "no language \"${language}\" found in ${langFilename}")
                  langData.language).file-types;
                addFiletypes = language: file-types: {
                  name = language;
                  file-types = (defaultFileTypes language) ++ file-types;
                };
              in
              [
                (addFiletypes "json" [ "flake.lock" "tfstate" ])
                (addFiletypes "toml" [ "Cargo.lock" ])
                {
                  name = "nix";
                  auto-format = true;
                }
                { name = "haskell"; auto-format = true; }
                {
                  name = "markdown";
                  auto-pairs = {
                    "_" = "_";
                    "*" = "*";
                    "`" = "`";
                    "$" = "$";
                    "<" = ">";
                    "(" = ")";
                    "[" = "]";
                    "{" = "}";
                    "|" = "|";
                    # TODO: implement support for multi-character auto-pairs, see:
                    # https://github.com/helix-editor/helix/issues/4035
                    # "__" = "__";
                    # "**" = "**";
                    # "```" = "```";
                    # "\{" = "\}";
                    # "\left(" = "\right)";
                    # "\left[" = "\right]";
                    # "\left\{" = "\right\}";
                    # "\left|" = "\right|";
                  };
                }
              ] ++ lib.optional cfg.helix-overlay {
                name = "typst";
                auto-format = true;
              };
            language-server.nil.config.nil.formatting.command = [
              "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt"
            ];
          };
          settings = {
            theme = "gruvbox";
            editor = {
              auto-info = false;
              idle-timeout = 0;
              scrolloff = 7;
              line-number = "relative";
              cursor-shape = {
                insert = "bar";
                normal = "block";
                select = "underline";
              };
              rulers = [ 80 100 120 160 ];
              indent-guides.render = true;
              statusline = {
                left = [
                  "file-name"
                  "spinner"
                ];
                right = [
                  "diagnostics"
                  "selections"
                  "position"
                  "file-encoding"
                  "file-type"
                ];
              };
              soft-wrap = {
                enable = true;
                wrap-indicator = "  ";
              };
            };
            keys = rec {
              select = rec {
                g.q = ":reflow";
                G = "goto_last_line";
                M = "match_brackets";
                p = "paste_clipboard_after";
                P = "paste_clipboard_before";
                "A-p" = "paste_after";
                "A-P" = "paste_before";
                y = "yank_main_selection_to_clipboard";
                Y = "yank_joined_to_clipboard";
                "A-y" = "yank";
                c = "change_selection_noyank";
                d = [ y "delete_selection" ];
                "A-d" = "delete_selection";
                R = "replace_selections_with_clipboard";
                "A-R" = "replace_with_yanked";
                X = "extend_line_up";
                W = ":write";
                Z = {
                  Q = ":quit!";
                  Z = ":write-quit";
                };
                space = {
                  i = [ ":toggle-option lsp.display-inlay-hints" ];
                  m = [ ":toggle-option auto-format" ];
                };
              };
              normal = select;
            };
          };
        };
        lf = {
          enable = true;
          commands = {
            archive = ''%echo "\"$fx\"" | string join '" "' | xargs arc archive "$argv" && lf -remote "send $id select \"$argv\""'';
            chmod = ''%echo "\"$fx\"" | string join '" "' | xargs chmod "$argv"; lf -remote "send $id reload"'';
            edit = ''
              ''${{
                  $EDITOR -- "$argv"
                  if test -e "$argv"
                      lf -remote "send $id select \"$argv\""
                  end
              }}
            '';
            mkdir = ''
              %{{
                  mkdir -p -- "$argv"
                  lf -remote "send $id select \"$argv\""
              }}
            '';
            touch = ''
              %{{
                  touch "$argv"
                  lf -remote "send $id select \"$argv\""
              }}
            '';
          };
          extraConfig = ''
            set cleaner ${config.xdg.configHome}/lf/cleaner
          '';
          keybindings = {
            "<esc>" = "clear";
            C = "push :chmod<space>";
            D = ''%echo "\"$fx\"" | string join '" "' | xargs trash'';
            E = "push :edit<space>";
            M = "push :mkdir<space>";
            R = "rename";
            X = ''push :archive<space>'';
            ge = "bottom";
            gi = "cd ~/repos/infra";
            gr = "cd ~/repos";
            r = "reload";
            t = "push :touch<space>";
            u = "%{{ ${trash-undo} }}";
            x = ''%arc unarchive "$f"'';
          };
          previewer.source = pkgs.writeShellScript "lf-previewer" ''
            ${pkgs.pistol}/bin/pistol "$@"

            # this prevents caching, which is desirable so that previews are
            # redrawn when the window is resized
            exit 1
          '';
          settings = {
            dirfirst = false;
            icons = true;
            promptfmt = ''\033[1;33m%u\033[0m in \033[1;36m%d\033[0m\033[1m%f\033[0m'';
            smartcase = true;
            shell = "fish";
            scrolloff = 7;
            period = 1;
          };
        };
        nix-index = {
          enable = true;
          enableBashIntegration = false;
          enableFishIntegration = false;
          enableZshIntegration = false;
        };
        pistol = {
          enable = true;
          associations = [
            {
              mime = "text/*";
              command = "bat --paging=never --color=always --style=auto --wrap=character --terminal-width=%pistol-extra0% --line-range=1:%pistol-extra1% %pistol-filename%";
            }
            {
              mime = "application/json";
              command = "bat --paging=never --color=always --style=auto --wrap=character --terminal-width=%pistol-extra0% --line-range=1:%pistol-extra1% %pistol-filename%";
            }
            {
              mime = "image/*";
              command = ''sh: if [ "$TERM" = xterm-kitty ]; then kitten icat --transfer-mode file --stdin no --place %pistol-extra0%x%pistol-extra1%@%pistol-extra2%x%pistol-extra3% %pistol-filename% </dev/null >/dev/tty && exit 1; else ${pkgs.chafa}/bin/chafa --format symbols --size %pistol-extra0%x%pistol-extra1% %pistol-filename%; fi'';
            }
            {
              mime = "application/pdf";
              command = ''sh: if [ "$TERM" = xterm-kitty ]; then ${pkgs.poppler_utils}/bin/pdftoppm -f 1 -l 1 %pistol-filename% -png | kitten icat --transfer-mode file --place %pistol-extra0%x%pistol-extra1%@%pistol-extra2%x%pistol-extra3% >/dev/tty && exit 1; else ${pkgs.chafa}/bin/chafa --format symbols --size %pistol-extra0%x%pistol-extra1% <(${pkgs.poppler_utils}/bin/pdftoppm -f 1 -l 1 %pistol-filename% -png); fi'';
            }
          ];
        };
        readline = {
          enable = true;
          variables.editing-mode = "vi";
          bindings."\\C-l" = "clear-display";
        };
        starship = {
          enable = true;
          enableBashIntegration = true;
          enableFishIntegration = true;
          enableZshIntegration = true;
          settings =
            let
              nerd-font-symbols-path = "${pkgs.starship.src}/docs/public/presets/toml/nerd-font-symbols.toml";
              nerd-font-symbols = builtins.fromTOML (builtins.readFile nerd-font-symbols-path);
            in
            lib.mkMerge [
              nerd-font-symbols
              {
                format = lib.concatStrings [
                  "$username"
                  "$hostname"
                  "$kubernetes"
                  "$directory"
                  "$sudo"
                  "$shlvl"
                  "$git_branch"
                  "$git_commit"
                  "$git_state"
                  "$git_status"
                  "$hg_branch"
                  "$docker_context"
                  "$package"
                  "$cmake"
                  "$dart"
                  "$dotnet"
                  "$elixir"
                  "$elm"
                  "$erlang"
                  "$golang"
                  "$helm"
                  "$java"
                  "$julia"
                  "$kotlin"
                  "$nim"
                  "$nodejs"
                  "$ocaml"
                  "$perl"
                  "$php"
                  "$purescript"
                  "$python"
                  "$ruby"
                  "$rust"
                  "$scala"
                  "$swift"
                  "$terraform"
                  "$vagrant"
                  "$zig"
                  "$nix_shell"
                  "$conda"
                  "$memory_usage"
                  "$aws"
                  "$gcloud"
                  "$openstack"
                  "$env_var"
                  "$crystal"
                  "$custom"
                  "$cmd_duration"
                  "$lua"
                  "$battery"
                  "$line_break"
                  "$jobs"
                  "$time"
                  "$status"
                  "$shell"
                  "$character"
                ];
                battery = {
                  format = "with [$symbol$percentage]($style) battery ";
                  full_symbol = "󰁹";
                  charging_symbol = "󰂈";
                  discharging_symbol = "󰁾";
                };
                character = {
                  success_symbol = "[>](green)";
                  error_symbol = "[>](red)";
                  vimcmd_symbol = "[<](blue)";
                  vimcmd_visual_symbol = "[<](yellow)";
                  vimcmd_replace_one_symbol = "[<](cyan)";
                  vimcmd_replace_symbol = "[<](cyan)";
                };
                cmd_duration.format = "for [$duration]($style) ";
                directory.format = "in [$path]($style) ";
                git_commit.format = "at [$hash]($style) [$tag]($style)";
                git_status = {
                  format = "(with [$all_status$ahead_behind]($style) )";
                  conflicted = "UU";
                  ahead = "A";
                  behind = "B";
                  diverged = "V";
                  untracked = "U";
                  stashed = "T";
                  modified = "M";
                  staged = "S";
                  renamed = "R";
                  deleted = "D";
                };
                hostname.format = "on [$hostname]($style) ";
                nix_shell = {
                  format = "in $state ";
                  impure_msg = "[ $name](bold purple)";
                  pure_msg = "[󰜗 $name](bold blue)";
                };
                package.style = "bold blue";
                shell = {
                  format = "[$indicator]($style) ";
                  disabled = false;
                };
                shlvl = {
                  format = "at depth [$shlvl]($style) ";
                  disabled = false;
                };
                sudo = {
                  disabled = false;
                  format = "with [sudo $symbol]($style) ";
                  symbol = "";
                };
                username = {
                  show_always = true;
                  format = "[$user]($style) ";
                };
              }
            ];
        };
        tmux = {
          enable = true;
          customPaneNavigationAndResize = true;
          escapeTime = 0;
          keyMode = "vi";
          mouse = true;
          sensibleOnTop = false;
          extraConfig = ''
            set-option -g status off

            bind -r _ split-window -v
            bind -r - split-window -v
            bind -r | split-window -h

            set -g pane-border-style 'fg=color7,bg=color0'
            set -g pane-active-border-style 'fg=color1,bg=color0'

            %if '#{||:#{==:#{TERM},xterm-kitty},#{==:#{TERM},xterm-256color}}'
            set -g default-terminal "screen-256color"
            %endif
            set-option -ga terminal-overrides ",xterm-kitty:Tc,xterm-256color:Tc"
          '';
        };
        zsh = {
          inherit (config.programs.fish) shellAliases;
          defaultKeymap = "viins";
        };
      };
  };
}
