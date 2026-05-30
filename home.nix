{ inputs, pkgs, ... }:
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

  # 기존 ~/.zshrc 의 PATH 한 줄을 선언적으로 대체한다.
  home.sessionPath = [ "$HOME/.local/bin" ];

  # zsh 를 home-manager 로 관리한다.
  # 시스템 레벨 programs.zsh(darwin.nix)는 /etc/zshrc 를 다루고,
  # 여기서는 사용자 ~/.zshrc 를 관리해 starship 통합 라인이 자동으로 들어가게 한다.
  programs.zsh.enable = true;

  # Starship 프롬프트. enableZshIntegration 이 기본 true 라서
  # ~/.zshrc 끝에 `eval "$(starship init zsh)"` 가 자동 추가된다.
  programs.starship.enable = true;

  # Ghostty 터미널.
  # 앱 바이너리(ghostty-bin)는 darwin.nix 의 systemPackages 가 설치하므로
  # 여기서는 package=null 로 두고 설정 파일(~/.config/ghostty/config)만 관리한다.
  programs.ghostty = {
    enable = true;
    package = null;
    settings = {
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
