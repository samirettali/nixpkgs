{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  fetchNpmDeps,
  writeShellApplication,
  cacert,
  curl,
  gnused,
  jq,
  nix-prefetch-github,
  prefetch-npm-deps,
}:
buildNpmPackage rec {
  pname = "gemini-cli";
  version = "0.1.7";

  src = fetchFromGitHub {
    owner = "google-gemini";
    repo = "gemini-cli";
    rev = "v${version}";
    hash = "sha256-DAenod/w9BydYdYsOnuLj7kCQRcTnZ81tf4MhLUug6c=";
  };

  npmDeps = fetchNpmDeps {
    inherit src;
    hash = "sha256-otogkSsKJ5j1BY00y4SRhL9pm7CK9nmzVisvGCDIMlU=";
  };

  preConfigure = ''
    mkdir -p packages/generated
    echo "export const GIT_COMMIT_INFO = { commitHash: '${src.rev}' };" > packages/generated/git-commit.ts
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib"

    cp -r node_modules "$out/lib/"

    rm -f "$out/lib/node_modules/@google/gemini-cli"
    rm -f "$out/lib/node_modules/@google/gemini-cli-core"

    cp -r packages/cli "$out/lib/node_modules/@google/gemini-cli"
    cp -r packages/core "$out/lib/node_modules/@google/gemini-cli-core"

    mkdir -p "$out/bin"
    ln -s ../lib/node_modules/@google/gemini-cli/dist/index.js "$out/bin/gemini"

    runHook postInstall
  '';

  postInstall = ''
    chmod +x "$out/bin/gemini"

    echo "Removing bundled eslint from gemini-cli to prevent collision"
    rm -rf $out/lib/node_modules/eslint

    # Also remove the symlink that points to the now-deleted directory.
    # We use -f to prevent an error if the symlink doesn't exist for some reason.
    rm -f $out/lib/node_modules/.bin/eslint
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "AI agent that brings the power of Gemini directly into your terminal";
    homepage = "https://github.com/google-gemini/gemini-cli";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [donteatoreo];
    platforms = lib.platforms.all;
    mainProgram = "gemini";
  };
}
