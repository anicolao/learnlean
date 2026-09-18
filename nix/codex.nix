# Upstream native releases, pinned independently of the Rocq/nixpkgs toolchain.
{ lib, stdenvNoCC, fetchurl, makeWrapper, ripgrep }:
let
  version = "0.154.0";
  releases = {
    aarch64-darwin = {
      platform = "darwin-arm64";
      target = "aarch64-apple-darwin";
      hash = "sha512-HP/vJCH/t2hB9Kg6hotN9UglClJ6/z584fal5lEP14C9gNAgAQS4/kTQC7l5V+BA3TqwDPwINSjul28cX8AYXg==";
    };
    x86_64-darwin = {
      platform = "darwin-x64";
      target = "x86_64-apple-darwin";
      hash = "sha512-2aqz+72Hop8PF2RYglQ4JnGjm3OlRIrTykJIT0hyLeUgM6NCFy09RgTmqRCoWliKQZjEn9jjZqUEp7QujAj77g==";
    };
    aarch64-linux = {
      platform = "linux-arm64";
      target = "aarch64-unknown-linux-musl";
      hash = "sha512-KmTCB6ST484zeYlPpKP/K5P/gRaYmt6TihVD+zotoe6O9q0JSBP+FYvCz4A/zZXR7xDOHURTSjHp0sD8wWS0YQ==";
    };
    x86_64-linux = {
      platform = "linux-x64";
      target = "x86_64-unknown-linux-musl";
      hash = "sha512-a4FI3A8sGtwGrOqltrPbrS2hajrHQG591EwmRfiRoLMb10VxdBtUGW4gu6IJVYENiYGA7k3P4jlRHEoCZU/s9Q==";
    };
  };
  release = releases.${stdenvNoCC.hostPlatform.system};
in stdenvNoCC.mkDerivation {
  pname = "codex";
  inherit version;
  src = fetchurl {
    url = "https://registry.npmjs.org/@openai/codex/-/codex-${version}-${release.platform}.tgz";
    inherit (release) hash;
  };
  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;
  dontStrip = true;
  dontPatchELF = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin" "$out/libexec/codex"
    cp -R vendor/${release.target}/. "$out/libexec/codex/"
    makeWrapper "$out/libexec/codex/bin/codex" "$out/bin/codex" \
      --prefix PATH : ${lib.makeBinPath [ ripgrep ]}
    runHook postInstall
  '';
  doInstallCheck = stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform;
  installCheckPhase = ''
    "$out/bin/codex" --version | grep -F '${version}'
  '';
  meta = {
    description = "Codex CLI with native app-server and resources";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    mainProgram = "codex";
    platforms = builtins.attrNames releases;
  };
}
