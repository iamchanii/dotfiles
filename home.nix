{ inputs, pkgs, config, ... }:
{
  imports = [ inputs.nix4nvchad.homeManagerModules.default ];

  home.stateVersion = "25.11";

  # 사용자 패키지
  home.packages = [
    pkgs.nodejs # Node.js (현재 LTS)
  ];

  # 패키지 매니저 쿨다운(최소 릴리스 경과 시간) = 1일.
  # 갓 게시돼 아직 검증되지 않은 버전의 설치를 하루 지연시켜, npm 공급망 공격
  # (악성 버전이 게시 후 수 시간~수 일 내 적발·삭제되는 패턴)을 방어한다.
  # 네 메이저 PM 모두 네이티브 지원하지만 키·파일·단위가 제각각이라 따로 적는다.
  #
  # 주의: 아래 파일들은 home-manager 가 nix store 로의 (읽기 전용) 심링크로 만들므로
  # npm login 등 ~/.npmrc 에 쓰는 작업은 프로젝트 .npmrc 나 환경변수로 처리해야 한다.

  # npm (>=11.10): min-release-age. 단위는 "일"이고 값은 정수만 허용
  # (`1d`/`24h` 같은 문자열은 거부됨). 1일 = 1.
  home.file.".npmrc".text = ''
    min-release-age=1
  '';

  # pnpm (>=11): minimumReleaseAge, 분 단위. pnpm 11 부터 이 설정은 .npmrc 가 아닌
  # 전역 YAML 설정(~/.config/pnpm/config.yaml)에서 읽는다. 1일 = 1440분.
  xdg.configFile."pnpm/config.yaml".text = ''
    minimumReleaseAge: 1440
  '';

  # yarn (berry >=4.10): npmMinimalAgeGate, 분 단위. `1d` 문자열은 day 접미사가
  # 무시되는 버그가 있어 분으로 명시한다. 1일 = 1440분.
  home.file.".yarnrc.yml".text = ''
    npmMinimalAgeGate: 1440
  '';

  # bun (>=1.3): [install].minimumReleaseAge, 초 단위. 1일 = 86400초.
  home.file.".bunfig.toml".text = ''
    [install]
    minimumReleaseAge = 86400
  '';

  # home-manager 자기 자신을 관리
  programs.home-manager.enable = true;

  # NvChad (nix4nvchad). nvim 실행 파일을 래핑하므로
  # programs.neovim.enable 과 동시 사용 금지.
  programs.nvchad.enable = true;

  # GitHub CLI
  programs.gh.enable = true;

  # nushell 을 home-manager 로 관리한다. macOS 에서는
  # ~/Library/Application Support/nushell/{env,config}.nu 가 선언적으로 생성된다.
  # 로그인 셸 지정은 darwin.nix 에서 한다.
  #
  # PATH 주의: zsh/bash 와 달리 nushell 은 Determinate Nix / nix-darwin 의 셸
  # 초기화 스니펫(/etc/zshrc 등)을 읽지 않고, home-manager 의 home.sessionPath
  # (POSIX hm-session-vars.sh)도 source 하지 않는다. 따라서 그 스니펫들이
  # 넣어주던 nix 관련 경로를 nushell env.nu 에서 직접 PATH 에 추가해야 한다.
  # extraEnv 는 env.nu 로 들어가며 config.nu(starship 통합)보다 먼저 로드된다.
  programs.nushell = {
    enable = true;
    shellAliases = {
      vim = "nvim";
    };
    extraEnv = ''
      $env.PATH = (
        $env.PATH
        | (if ($in | describe) == "string" { split row (char esep) } else { $in })
        | prepend [
            "${config.home.profileDirectory}/bin" # home-manager 패키지 (starship 등)
            "/run/current-system/sw/bin"           # nix-darwin 시스템 패키지 (darwin-rebuild 등)
            "/nix/var/nix/profiles/default/bin"     # Determinate Nix (nix)
            "${config.home.homeDirectory}/.local/bin"
        ]
        | uniq
      )
    '';
  };

  # Starship 프롬프트.
  # enableNushellIntegration 이 기본 true 라서, nushell 이 켜져 있으면
  # nushell config 에 starship init 통합 스크립트가 자동으로 삽입된다.
  # (https://www.nushell.sh/book/3rdpartyprompts.html 의 수동 설정을 대체)
  programs.starship.enable = true;

  # Ghostty 터미널.
  # 앱 바이너리(ghostty-bin)는 darwin.nix 의 systemPackages 가 설치하므로
  # 여기서는 package=null 로 두고 설정 파일(~/.config/ghostty/config)만 관리한다.
  programs.ghostty = {
    enable = true;
    package = null;
    settings = {
      # Ghostty 는 기본적으로 $SHELL 환경변수를 따르는데, macOS GUI 로그인 세션의
      # $SHELL 은 로그인 시점 값(/bin/zsh)으로 캐시돼 dscl 로 셸을 바꿔도 재로그인
      # 전까지 갱신되지 않는다. 그래서 셸을 nushell 로 명시해 즉시·확실하게 고정한다.
      # 안정 경로(/run/current-system/sw/bin)를 써서 store 해시 변화에 영향받지 않게 한다.
      command = "/run/current-system/sw/bin/nu";
      theme = "Catppuccin Mocha";
      # CodexMono EA Nerd: 라틴+한글+일본어+중국어(간체) + Nerd Font 아이콘을
      # 단일 폰트로 커버하므로 폴백이 필요 없다.
      # (폰트 자체는 darwin.nix 의 fonts.packages 가 설치)
      font-family = "CodexMono EA Nerd";
      # CodexMono 는 합자(ligature)를 지원하지 않으므로 명시적으로 끈다.
      font-feature = [ "-calt" "-liga" "-dlig" ];
      font-size = 14;
      background-opacity = 0.95;
      cursor-style = "block";
      macos-option-as-alt = true;
      window-save-state = "always";
    };
  };
}
