{ pkgs }:
pkgs.writeShellApplication {
  name = "sf-tutor";
  runtimeInputs = [ pkgs.python3 pkgs.codex ];
  text = ''
    export SF_CODEX_BIN="${pkgs.codex}/bin/codex"
    exec ${pkgs.python3}/bin/python ${../prototype}/tutor.py "$@"
  '';
}
