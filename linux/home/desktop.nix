{ pkgs, ... }:
{
  # Fedora/KDE 세션이 Nix profile의 desktop entry, 아이콘, terminfo를 찾도록 한다.
  targets.genericLinux.enable = true;

  # Nix GUI 앱이 기대하는 /run/opengl-driver에 일관된 Mesa 스택을 제공한다.
  # 최초 1회 `make setup-gpu-linux`로 시스템 링크를 설치해야 한다.
  targets.genericLinux.gpu.enable = true;

  xdg.enable = true;

  home.packages = with pkgs; [
    bun
    (stdenvNoCC.mkDerivation (finalAttrs: {
      pname = "pnpm";
      version = "12.4.0";
      src = fetchurl {
        url = "https://registry.npmjs.org/pnpm/-/pnpm-${finalAttrs.version}.tgz";
        hash = "sha512-N1NsJu1Aq0E0tlEeCfayfz67RWh0aPJAbKOAUnmk5coVjBkxNQrZd01qshCNcbPbrrOZQxWSlDdeTQU+jgVoXA==";
      };
      nativeSrc = fetchurl {
        url = "https://registry.npmjs.org/@pnpm/exe.linux-arm64/-/exe.linux-arm64-${finalAttrs.version}.tgz";
        hash = "sha512-6npQUwq3D/WXbTgR4evApEKQ9ITznZ6Iz/dptcjBzA7+wSLTaYkK98Od2wsHCoPmEFb9tGtM+cvG82+wy0o9uA==";
      };
      nativeBuildInputs = [ autoPatchelfHook installShellFiles ];
      buildInputs = [ stdenv.cc.cc.lib ];
      dontConfigure = true;
      dontBuild = true;
      installPhase = ''
        runHook preInstall
        mkdir -p $out/{bin,libexec/pnpm}
        # 네이티브 실행 파일 옆에 node-gyp용 dist 데이터를 보존한다.
        cp -R dist $out/libexec/pnpm/
        tar -xOf $nativeSrc package/pnpm > $out/libexec/pnpm/pnpm
        chmod +x $out/libexec/pnpm/pnpm
        for cmd in pnpm pn pnpx pnx; do
          ln -s $out/libexec/pnpm/pnpm $out/bin/$cmd
        done
        runHook postInstall
      '';
      postPhases = [ "postPatchelf" ];
      postPatchelf = ''
        installShellCompletion --cmd pnpm \
          --bash <($out/bin/pnpm completion bash) \
          --fish <($out/bin/pnpm completion fish) \
          --zsh <($out/bin/pnpm completion zsh)
      '';
      meta = pnpm.meta // {
        changelog = "https://github.com/pnpm/pnpm/releases/tag/v${finalAttrs.version}";
        platforms = [ "aarch64-linux" ];
      };
    }))
    chromium
    _1password-gui
    _1password-cli
  ];
}
