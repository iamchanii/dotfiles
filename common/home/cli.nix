{ inputs, lib, pkgs, ... }:
let
  pnpm = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "pnpm";
    version = "12.4.0";
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/pnpm/-/pnpm-${finalAttrs.version}.tgz";
      hash = "sha512-N1NsJu1Aq0E0tlEeCfayfz67RWh0aPJAbKOAUnmk5coVjBkxNQrZd01qshCNcbPbrrOZQxWSlDdeTQU+jgVoXA==";
    };
    nativeSrc = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@pnpm/exe.${pkgs.stdenv.hostPlatform.parsed.kernel.name}-arm64/-/exe.${pkgs.stdenv.hostPlatform.parsed.kernel.name}-arm64-${finalAttrs.version}.tgz";
      hash = {
        aarch64-linux = "sha512-6npQUwq3D/WXbTgR4evApEKQ9ITznZ6Iz/dptcjBzA7+wSLTaYkK98Od2wsHCoPmEFb9tGtM+cvG82+wy0o9uA==";
        aarch64-darwin = "sha512-75EYiF8GuiTsnvP4cbZsviMBjohXUYtg2zjD4gdfhqxlU1y9Nj+KdEsbH4jfgB/FgyJSYPB2rqfmvvgLnRlVug==";
      }.${pkgs.stdenv.hostPlatform.system};
    };
    nativeBuildInputs = [ pkgs.installShellFiles ]
      ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.autoPatchelfHook ];
    buildInputs = lib.optionals pkgs.stdenv.isLinux [ pkgs.stdenv.cc.cc.lib ];
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
    postPhases = [ "installCompletions" ];
    installCompletions = ''
      installShellCompletion --cmd pnpm \
        --bash <($out/bin/pnpm completion bash) \
        --fish <($out/bin/pnpm completion fish) \
        --zsh <($out/bin/pnpm completion zsh)
    '';
    meta = pkgs.pnpm.meta // {
      changelog = "https://github.com/pnpm/pnpm/releases/tag/v${finalAttrs.version}";
      platforms = [ "aarch64-linux" "aarch64-darwin" ];
    };
  });
in
{
  # 사용자 패키지
  home.packages =
    [
      pkgs.nodejs # Node.js (현재 LTS)
      pnpm # pnpm 12.4.0
      pkgs.gh # 설정 파일은 GitHub CLI가 직접 관리
      inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
    ]
    # uv 는 기존 Mac 구성에만 유지한다.
    ++ lib.optionals pkgs.stdenv.isDarwin [ pkgs.uv ];

  # home-manager 자기 자신을 관리
  programs.home-manager.enable = true;

  # Git
  programs.git = {
    enable = true;
    settings.user.name = "Chanhee Lee";
    settings.user.email = "contact@imch.dev";
    # git init 시 기본 브랜치를 main 으로 설정
    settings.init.defaultBranch = "main";
    # Git 설정은 읽기 전용으로 생성되므로 gh auth setup-git 대신 선언적으로 관리한다.
    settings.credential."https://github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
    # git merge 자체를 squash 기본값으로 바꾸는 config 는 없으므로 alias 로 제공
    settings.alias = {
      sm = "merge --squash";
    };
  };
}
