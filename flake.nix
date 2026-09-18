{
  description = "Logical Foundations: Rocq, Neovim, and live graphical documentation";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      sfNvimLua = ''
        vim.g.mapleader = " "
        vim.g.maplocalleader = " "

        vim.opt.number = true
        vim.opt.relativenumber = false
        vim.opt.signcolumn = "yes"
        vim.opt.splitright = true
        vim.opt.splitbelow = true
        vim.opt.termguicolors = true
        vim.opt.updatetime = 200
        vim.opt.mouse = "a"

        -- Palettescheme (Standalone)
        vim.cmd([[
" palettescheme.vim
" A pure 16-color semantic colorscheme for shared tmux sessions.
" Bypasses Truecolor to rely entirely on the host terminal's 0-15 palette.

highlight clear
if exists('syntax_on')
  syntax reset
endif

let g:colors_name = 'palettescheme'

" 1. The Golden Rule: Disable Truecolor
" This forces Neovim to emit standard cterm index codes (0-15) 
" rather than literal hex values.
set notermguicolors

" Let Neovim detect light/dark from the terminal.
" Use the terminal default background instead of palette slot 0.

" --- Core UI ---
" 0: Primary Background, 15: Primary Text
hi Normal       ctermfg=NONE ctermbg=NONE    cterm=NONE
hi EndOfBuffer  ctermfg=8    ctermbg=NONE    cterm=NONE

" 8: Subtle Background (Gutters, Splits, Highlights)

" line numbers and sign columns make up the gutter to the
" left of the text. Same as bg so that there's no visible
" gutter
hi LineNr       ctermfg=10   ctermbg=NONE    cterm=NONE
hi LineNrAbove  ctermfg=10   ctermbg=NONE    cterm=NONE
hi LineNrBelow  ctermfg=10   ctermbg=NONE    cterm=NONE
hi SignColumn   ctermfg=10   ctermbg=NONE    cterm=NONE
hi FoldColumn   ctermfg=10   ctermbg=NONE    cterm=NONE
hi CursorLineSign ctermfg=10 ctermbg=NONE    cterm=NONE
hi CursorLineFold ctermfg=10 ctermbg=NONE    cterm=NONE

hi CursorLine   ctermfg=NONE ctermbg=8    cterm=NONE
hi CursorLineNr ctermfg=10   ctermbg=NONE    cterm=NONE
hi ColorColumn  ctermfg=NONE ctermbg=8    cterm=NONE

" hi VertSplit    ctermfg=7   ctermbg=NONE    cterm=NONE
hi WinSeparator    ctermfg=7   ctermbg=NONE    cterm=NONE
hi StatusLine   ctermfg=7   ctermbg=NONE    cterm=NONE
hi StatusLineNC ctermfg=7   ctermbg=NONE    cterm=NONE

" --- Syntax Highlighting ---
" Comments (Muted/Grey)
hi Comment      ctermfg=7   ctermbg=NONE cterm=italic

" Constants (Cyan/Magenta)
hi Constant     ctermfg=6    ctermbg=NONE cterm=NONE
hi String       ctermfg=6    ctermbg=NONE cterm=NONE
hi Number       ctermfg=6    ctermbg=NONE cterm=NONE
hi Boolean      ctermfg=5    ctermbg=NONE cterm=NONE

" Identifiers (Blue)
hi Identifier   ctermfg=4    ctermbg=NONE cterm=NONE
hi Function     ctermfg=4    ctermbg=NONE cterm=NONE

" Statements (Green/Yellow)
hi Statement    ctermfg=2    ctermbg=NONE cterm=NONE
hi Keyword      ctermfg=2    ctermbg=NONE cterm=NONE
hi Conditional  ctermfg=2    ctermbg=NONE cterm=NONE
hi Repeat       ctermfg=2    ctermbg=NONE cterm=NONE

" Preprocessors (Orange/Red)
hi PreProc      ctermfg=9    ctermbg=NONE cterm=NONE
hi Include      ctermfg=9    ctermbg=NONE cterm=NONE
hi Define       ctermfg=9    ctermbg=NONE cterm=NONE
hi Macro        ctermfg=9    ctermbg=NONE cterm=NONE

" Types (Yellow)
hi Type         ctermfg=3    ctermbg=NONE cterm=NONE
hi StorageClass ctermfg=3    ctermbg=NONE cterm=NONE
hi Structure    ctermfg=3    ctermbg=NONE cterm=NONE

" Special Elements (Magenta/Red)
hi Special      ctermfg=5    ctermbg=NONE cterm=NONE
hi SpecialChar  ctermfg=1    ctermbg=NONE cterm=NONE
hi Tag          ctermfg=5    ctermbg=NONE cterm=NONE
hi Delimiter    ctermfg=15   ctermbg=NONE cterm=NONE

" --- Extras & Popups ---
hi Underlined   ctermfg=4    ctermbg=NONE cterm=underline
hi Error        ctermfg=15   ctermbg=1    cterm=bold
hi Todo         ctermfg=0    ctermbg=5    cterm=bold
hi MatchParen   ctermfg=0    ctermbg=6    cterm=bold
hi Search       ctermfg=0    ctermbg=3    cterm=NONE
hi IncSearch    ctermfg=0    ctermbg=9    cterm=NONE
hi Visual       ctermfg=NONE ctermbg=8    cterm=NONE
hi DiffAdd      ctermfg=NONE ctermbg=193  cterm=NONE
hi DiffDelete   ctermfg=NONE ctermbg=224  cterm=NONE
hi DiffChange   ctermfg=NONE ctermbg=187  cterm=NONE
hi DiffText     ctermfg=NONE ctermbg=229  cterm=NONE

" Pmenu (Autocomplete dropdowns)
hi Pmenu        ctermfg=15   ctermbg=8    cterm=NONE
hi PmenuSel     ctermfg=0    ctermbg=4    cterm=NONE
hi PmenuSbar    ctermfg=NONE ctermbg=8    cterm=NONE
hi PmenuThumb   ctermfg=NONE ctermbg=10   cterm=NONE

        ]])

        -- Coqtail configuration

        vim.g.coqtail_noimap = 1
        vim.g.coqtail_map_prefix = "<leader>c"
        vim.g.coqtail_imap_prefix = false
        vim.g.coqtail_goal_lines = 12
        vim.g.coqtail_tagfunc = 1
        vim.g.coqtail_treat_stderr_as_warning = 1

        vim.api.nvim_create_autocmd("FileType", {
          pattern = "coq",
          callback = function(args)
            vim.opt_local.shiftwidth = 2
            vim.opt_local.tabstop = 2
            vim.opt_local.expandtab = true
            vim.opt_local.colorcolumn = ""

            vim.b.coqtail_coq_prog = "coqidetop"

            local map = function(lhs, rhs, desc)
              vim.keymap.set("n", lhs, rhs, { buffer = args.buf, silent = true, desc = desc })
            end
            local map_both = function(lhs, rhs, desc)
              vim.keymap.set({ "n", "i" }, lhs, rhs, { buffer = args.buf, silent = true, desc = desc })
            end
            local follow = function(cmd)
              return function()
                local keys = vim.api.nvim_replace_termcodes(cmd, true, false, true)
                vim.api.nvim_feedkeys(keys, "m", false)
                vim.schedule(function()
                  if vim.fn.exists(":RocqJumpToEnd") == 2 then
                    vim.cmd("silent! RocqJumpToEnd")
                    vim.cmd("normal! zz")
                  end
                end)
              end
            end

            map("<leader>cc", "<cmd>RocqStart<cr>", "Start Coqtail")
            map("<leader>cq", "<cmd>RocqStop<cr>", "Stop Coqtail")
            map("<leader>cj", "<Plug>RocqNext", "Check next sentence")
            map("<leader>ck", "<Plug>RocqUndo", "Undo checked sentence")
            map("<leader>cl", "<Plug>RocqToLine", "Check to cursor")
            map("<leader>cT", "<cmd>RocqToTop<cr>", "Rewind to top")
            map("<leader>cr", "<cmd>RocqRestorePanels<cr>", "Restore goal panels")
            map("<leader>ch", "<cmd>Rocq Check<cr>", "Check symbol")
            map("<leader>cp", "<cmd>Rocq Print<cr>", "Print symbol")
            map("<leader>ca", "<cmd>Rocq About<cr>", "About symbol")
            map("<leader>cs", "<cmd>Rocq Search<cr>", "Search")
            map_both("<M-Up>", follow("<Plug>RocqUndo"), "Undo checked sentence and follow state")
            map_both("<M-Down>", follow("<Plug>RocqNext"), "Check next sentence and follow state")
            map_both("<M-Right>", follow("<Plug>RocqToLine"), "Check to cursor and follow state")

            if vim.env.SF_DOC_TEST == "1" then return end
            if vim.b.sf_coqtail_started then
              return
            end

            vim.b.sf_coqtail_started = true
            vim.schedule(function()
              if not vim.api.nvim_buf_is_valid(args.buf) then
                return
              end
              if vim.bo[args.buf].filetype ~= "coq" then
                return
              end
              if vim.fn.exists(":RocqStart") ~= 2 then
                return
              end
              vim.api.nvim_buf_call(args.buf, function()
                vim.cmd("silent! RocqStart")
              end)
            end)
          end,
        })


        require("sf_docs").setup()
        require("sf_tutor").setup()

        -- Preserve the original checked-proof green even when terminal background
        -- detection resets Neovim's built-in DiffAdd highlight.
        local function proof_highlights()
          vim.api.nvim_set_hl(0, "CoqtailChecked", { ctermbg = 193, bg = "#d7ffaf" })
        end
        vim.api.nvim_create_autocmd("ColorScheme", { callback = proof_highlights })
        vim.api.nvim_create_autocmd("OptionSet", {
          pattern = "background",
          callback = proof_highlights,
        })
        proof_highlights()
      '';
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f:
        lib.genAttrs systems (
          system:
          let
            pkgs = import nixpkgs { inherit system; };
            coq = if pkgs ? coq_9_0 then pkgs.coq_9_0 else pkgs.coq;
            coqPackages =
              if pkgs ? coqPackages_9_0 then
                pkgs.coqPackages_9_0
              else if pkgs ? coqPackages then
                pkgs.coqPackages
              else
                throw "No Coq package set found in nixpkgs for ${system}";
            renderPython = pkgs.python3.withPackages (ps: [ ps.weasyprint ps.pillow ps.pynvim ]);
            docRenderer = pkgs.writeShellApplication {
              name = "sf-doc-render";
              runtimeInputs = [ renderPython coq pkgs.poppler-utils ];
              text = ''
                export FONTCONFIG_FILE="${pkgs.makeFontsConf { fontDirectories = [ pkgs.dejavu_fonts ]; }}"
                exec ${renderPython}/bin/python ${./prototype/render.py} "$@"
              '';
            };
            tutor = pkgs.writeShellApplication {
              name = "sf-tutor";
              runtimeInputs = [ renderPython ];
              text = ''
                exec ${renderPython}/bin/python ${./prototype}/tutor.py "$@"
              '';
            };
            docPlugin = pkgs.vimUtils.buildVimPlugin {
              pname = "sf-docs";
              version = "0.1.0";
              src = ./prototype;
              doCheck = false;
            };
            sfNvimBase = pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
              plugins = [
                { plugin = pkgs.vimPlugins.Coqtail; }
                { plugin = pkgs.vimPlugins.image-nvim.overrideAttrs (old: {
                    patches = (old.patches or []) ++ [ ./prototype/image-inline-anchor.patch ];
                  }); }
                { plugin = docPlugin; }
                
              ];
              luaRcContent = sfNvimLua;
              withPython3 = true;
              wrapRc = true;
            };
            sfNvim = pkgs.symlinkJoin {
              name = "sf-nvim";
              paths = [ sfNvimBase ];
              nativeBuildInputs = [ pkgs.makeWrapper ];
              postBuild = "wrapProgram \"$out/bin/nvim\" --prefix PATH : ${lib.makeBinPath [ coq pkgs.git pkgs.ripgrep docRenderer tutor pkgs.imagemagick ]} --set-default ROCQPATH \"${coqPackages.stdlib}/lib/coq/9.0/user-contrib\" --unset COQPATH";
            };
          in
          f pkgs coq coqPackages sfNvim docRenderer renderPython
        );
    in
    {
      packages = forAllSystems (
        pkgs: coq: coqPackages: sfNvim: docRenderer: renderPython:
        {
          default = sfNvim;
          nvim = sfNvim;
          renderer = docRenderer;
          test-python = renderPython;
        }
      );

      apps = forAllSystems (
        pkgs: coq: coqPackages: sfNvim: docRenderer: renderPython:
        {
          kitty = {
            type = "app";
            program = "${pkgs.writeShellScript "sf-kitty" ''
              unset TMUX TMUX_PANE
              exec ${pkgs.kitty}/bin/kitty --title "Logical Foundations" ${sfNvim}/bin/nvim "$@"
            ''}";
          };
          default = {
            type = "app";
            program = "${sfNvim}/bin/nvim";
          };
          nvim = {
            type = "app";
            program = "${sfNvim}/bin/nvim";
          };
        }
      );

      checks = forAllSystems (
        pkgs: coq: coqPackages: sfNvim: docRenderer: renderPython:
        {
          documentation = pkgs.runCommand "sf-documentation-tests" {
            nativeBuildInputs = [ sfNvim docRenderer renderPython coq ];
          } ''
            export HOME="$TMPDIR/home"
            mkdir -p "$HOME"
            export SF_DOC_TEST=1
            python ${./prototype}/tests/test_tutor.py
            python ${./prototype}/tests/test_tutor_editor.py
            python ${./prototype/tests/test_renderer.py}
            nvim --headless -c "luafile ${./prototype/tests/test_plugin.lua}"
            touch "$out"
          '';
        }
      );

      devShells = forAllSystems (
        pkgs: coq: coqPackages: sfNvim: docRenderer: renderPython:
        {
          default = pkgs.mkShell {
            packages =
              [
                sfNvim
                docRenderer
                renderPython
                pkgs.kitty
                coq
                coqPackages.stdlib
                pkgs.ocaml
                pkgs.gnumake
                pkgs.curl
                pkgs.git
                pkgs.ripgrep
                pkgs.fd
              ]
              ++ lib.optionals (coqPackages ? coq-lsp) [ coqPackages.coq-lsp ]
              ++ lib.optionals (coqPackages ? vscoq-language-server) [ coqPackages.vscoq-language-server ]
              ++ lib.optionals (pkgs.ocamlPackages ? findlib) [ pkgs.ocamlPackages.findlib ];
            shellHook = ''
              if [ -d "$PWD/lf" ]; then
                export SF_BOOK_DIR="$PWD/lf"
              else
                export SF_BOOK_DIR="$PWD/lf-current"
              fi

              export ROCQPATH="${coqPackages.stdlib}/lib/coq/9.0/user-contrib''${ROCQPATH:+:$ROCQPATH}"
              unset COQPATH

              if [ -d "$SF_BOOK_DIR" ]; then
                alias lf='cd "$SF_BOOK_DIR"'
              fi

              printf 'Software Foundations Logical Foundations shell\n'
              if [ -d "$SF_BOOK_DIR" ]; then
                printf '  book dir: %s\n' "$SF_BOOK_DIR"
                printf '  useful commands: lf | nvim "$SF_BOOK_DIR/Basics.v" | make -C "$SF_BOOK_DIR" Basics.vo\n'
              else
                printf '  book dir not found; download https://softwarefoundations.cis.upenn.edu/lf-current/lf.tgz and extract it here\n'
              fi
            '';
          };
        }
      );
    };
}
