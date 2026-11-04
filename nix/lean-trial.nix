{ pkgs }:
let
  renderPython = pkgs.python3.withPackages (ps: [ ps.weasyprint ps.pillow ps.markdown-it-py ]);
  renderer = pkgs.writeShellApplication {
    name = "sf-doc-render";
    runtimeInputs = [ renderPython pkgs.poppler-utils ];
    text = ''
      export FONTCONFIG_FILE="${pkgs.makeFontsConf { fontDirectories = [ pkgs.dejavu_fonts ]; }}"
      exec ${renderPython}/bin/python ${../prototype/render.py} "$@"
    '';
  };
  docs = pkgs.vimUtils.buildVimPlugin {
    pname = "sf-docs";
    version = "0.1.0";
    src = ../prototype;
    doCheck = false;
  };
  base = pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
    plugins = [ pkgs.vimPlugins.lean-nvim docs
      (pkgs.vimPlugins.image-nvim.overrideAttrs (old: {
        patches = (old.patches or []) ++ [ ../prototype/kitty-transport.patch ];
      }))
    ];
    luaRcContent = ''
      require('sf_docs').setup()
      require('sf_lean').setup()
      require('lean').setup { mappings = true }
    '';
    wrapRc = true;
  };
  editor = pkgs.symlinkJoin {
    name = "lean-trial-nvim";
    paths = [ base ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/nvim" --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.lean4 renderer pkgs.tmux ]}
    '';
  };
  launcher = pkgs.writeShellApplication {
    name = "lean-try";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      if [ "$#" -eq 0 ]; then
        trial_dir=$(mktemp -d "$PWD/lean-trial.XXXXXX")
        cp ${../lean-trial/Main.lean} "$trial_dir/Main.lean"
        cp ${../lean-trial/lakefile.toml} "$trial_dir/lakefile.toml"
        chmod u+w "$trial_dir/Main.lean" "$trial_dir/lakefile.toml"
        printf '%s\n' 'leanprover/lean4:v${pkgs.lean4.version}' > "$trial_dir/lean-toolchain"
        printf 'Your editable Lean project: %s\n' "$trial_dir"
        cd "$trial_dir"
        set -- Main.lean
      fi
      exec ${editor}/bin/nvim "$@"
    '';
  };
in {
  inherit editor launcher;
  check = pkgs.runCommand "lean-trial-check" {
    nativeBuildInputs = [ editor pkgs.lean4 renderer renderPython ];
  } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME" project
    cp ${../lean-trial/Main.lean} project/Main.lean
    cp ${../lean-trial/lakefile.toml} project/lakefile.toml
    chmod -R u+w project
    cd project
    python ${../prototype/tests/test_lean_renderer.py}
    nvim --headless -c "luafile ${../prototype/tests/test_lean_docs.lua}"
    lake build
    nvim --headless Main.lean -c "luafile ${../lean-trial/check.lua}"
    # Exercise standalone files both inside a Git root and without any root marker.
    rm lakefile.toml
    mkdir .git
    nvim --headless Main.lean -c "luafile ${../lean-trial/check.lua}"
    rmdir .git
    nvim --headless Main.lean -c "luafile ${../lean-trial/check.lua}"
    touch "$out"
  '';
}
