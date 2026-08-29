{ inputs, pkgs, ... }:
let
  python = pkgs.python3.withPackages (ps: [ ps.brotli ps.fonttools ]);

  nerdFonts = pkgs.fetchurl {
    url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip";
    hash = "sha256-dvBf86zkikZKbKV5d5mHhP9727ZabZFdfkAc05J8STw=";
  };

  pretendard = pkgs.fetchurl {
    url = "https://github.com/orioncactus/pretendard/releases/download/v1.3.9/Pretendard-1.3.9.zip";
    hash = "sha256-BL41GnTWv31gxICjCH5R0YVIXTWlICMUKvHfGeuMQoo=";
  };

  jetendard = pkgs.stdenvNoCC.mkDerivation {
    pname = "jetendard";
    version = "0-unstable-2026-07-07";
    src = inputs.jetendard;
    nativeBuildInputs = [ pkgs.unzip python ];

    buildPhase = ''
      runHook preBuild
      mkdir -p upstream/jetbrainsmono upstream/pretendard
      unzip -j ${nerdFonts} 'JetBrainsMonoNerdFontMono-*.ttf' -d upstream/jetbrainsmono
      unzip -j ${pretendard} 'public/static/alternative/Pretendard-*.ttf' -d upstream/pretendard
      PYTHONPATH="$PWD/src" ${python}/bin/python -m jetendard.cli --all
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/share/fonts/truetype"
      cp fonts/ttf/*.ttf "$out/share/fonts/truetype/"
      runHook postInstall
    '';
  };
in
{
  fonts.fontconfig.enable = true;
  home.packages = [ jetendard ];
}
