{
  lib,
  stdenv,
  callPackage,
  vscode-generic,
  fetchurl,
  appimageTools,
  undmg,
  commandLineArgs ? "",
  useVSCodeRipgrep ? stdenv.hostPlatform.isDarwin,
}: let
  inherit (stdenv) hostPlatform;
  finalCommandLineArgs = "--update=false " + commandLineArgs;

  sources = {
    x86_64-linux.url = "https://downloads.cursor.com/production/5b19bac7a947f54e4caa3eb7e4c5fbf832389853/linux/x64/Cursor-1.1.6-x86_64.AppImage";
    x86_64-linux.hash = "sha256-T0vJRs14tTfT2kqnrQWPFXVCIcULPIud1JEfzjqcEIM=";
    aarch64-linux.url = "https://downloads.cursor.com/production/5b19bac7a947f54e4caa3eb7e4c5fbf832389853/linux/arm64/Cursor-1.1.6-aarch64.AppImage";
    aarch64-linux.hash = "sha256-HKr87IOzSNYWIYBxVOef1758f+id/t44YM5+SNunkTs=";
    x86_64-darwin.url = "https://downloads.cursor.com/production/5b19bac7a947f54e4caa3eb7e4c5fbf832389853/darwin/x64/Cursor-darwin-x64.dmg";
    x86_64-darwin.hash = "sha256-gzVucvipWQW7/ClwocPrszHruDbbU4KmccgdBFS5PbQ=";
    aarch64-darwin.url = "https://downloads.cursor.com/production/5b19bac7a947f54e4caa3eb7e4c5fbf832389853/darwin/arm64/Cursor-darwin-arm64.dmg";
    aarch64-darwin.hash = "sha256-7kjPfJV7XJqmllB30+rYuNBTCMPojyVBYHpavruAFr8=";
  };

  source = fetchurl {
    url = sources.${hostPlatform.system}.url;
    hash = sources.${hostPlatform.system}.hash;
  };
in
  (callPackage vscode-generic rec {
    inherit useVSCodeRipgrep;
    commandLineArgs = finalCommandLineArgs;

    version = "1.1.6";
    pname = "cursor";

    # You can find the current VSCode version in the About dialog:
    # workbench.action.showAboutDialog (Help: About)
    vscodeVersion = "1.96.2";

    executableName = "cursor";
    longName = "Cursor";
    shortName = "cursor";
    libraryName = "cursor";
    iconName = "cursor";

    src =
      if hostPlatform.isLinux
      then
        appimageTools.extract {
          inherit pname version;
          src = source;
        }
      else source;

    sourceRoot =
      if hostPlatform.isLinux
      then "${pname}-${version}-extracted/usr/share/cursor"
      else "Cursor.app";

    tests = {};

    updateScript = ./update.sh;

    # Editing the `cursor` binary within the app bundle causes the bundle's signature
    # to be invalidated, which prevents launching starting with macOS Ventura, because Cursor is notarized.
    # See https://eclecticlight.co/2022/06/17/app-security-changes-coming-in-ventura/ for more information.
    dontFixup = stdenv.hostPlatform.isDarwin;

    # Cursor has no wrapper script.
    patchVSCodePath = false;

    meta = {
      description = "AI-powered code editor built on vscode";
      homepage = "https://cursor.com";
      changelog = "https://cursor.com/changelog";
      license = lib.licenses.unfree;
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      maintainers = with lib.maintainers; [
        aspauldingcode
        prince213
      ];
      platforms =
        [
          "aarch64-linux"
          "x86_64-linux"
          "aarch64-darwin"
          "x86_64-darwin"
        ]
        ++ lib.platforms.darwin;
      mainProgram = "cursor";
    };
  }).overrideAttrs
  (oldAttrs: {
    nativeBuildInputs =
      (oldAttrs.nativeBuildInputs or [])
      ++ lib.optionals hostPlatform.isDarwin [undmg];

    preInstall =
      (oldAttrs.preInstall or "")
      + lib.optionalString hostPlatform.isLinux ''
        mkdir -p bin
        ln -s ../cursor bin/cursor
      '';

    passthru =
      (oldAttrs.passthru or {})
      // {
        inherit sources;
        updateScript = ./update.sh;
      };
  })
