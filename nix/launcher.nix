{ pkgs, rocq }:
let
  lean = import ./lean-trial.nix { inherit pkgs; };
  script = pkgs.replaceVars ../prototype/launch.py {
    rocq = "${rocq}/bin/nvim";
    lean = "${lean.editor}/bin/nvim";
  };
in pkgs.writeShellApplication {
  name = "nvim";
  text = ''
    exec ${pkgs.python3}/bin/python ${script} "$@"
  '';
}
