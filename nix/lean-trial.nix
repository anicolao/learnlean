{ pkgs }:
let
  base = pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
    plugins = [ pkgs.vimPlugins.lean-nvim ];
    luaRcContent = ''
      require('lean').setup { mappings = true }
    '';
    wrapRc = true;
  };
  editor = pkgs.symlinkJoin {
    name = "lean-trial-nvim";
    paths = [ base ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/nvim" --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.lean4 ]}
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
    nativeBuildInputs = [ editor pkgs.lean4 ];
  } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME" project
    cp ${../lean-trial/Main.lean} project/Main.lean
    cp ${../lean-trial/lakefile.toml} project/lakefile.toml
    chmod -R u+w project
    cd project
    lake build
    nvim --headless Main.lean -c "luafile ${../lean-trial/check.lua}"
    touch "$out"
  '';
}
