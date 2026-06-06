{ ... }:
{
  # Ghostty 터미널.
  # 앱 바이너리(ghostty-bin)는 darwin/system.nix 의 systemPackages 가 설치하므로
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
      # 영문: JetBrains Mono, 한글 폴백: GalmuriMono11
      # (두 폰트 모두 darwin/fonts.nix 의 fonts.packages 가 설치)
      font-family = [
        "JetBrains Mono"
        "GalmuriMono11"
      ];
      font-feature = [ "-calt" "-liga" "-dlig" ];
      font-size = 14;
      background-opacity = 0.95;
      cursor-style = "block";
      macos-option-as-alt = true;
      window-save-state = "always";
    };
  };

  # Zellij 터미널 멀티플렉서.
  # home-manager 의 zellij 모듈은 bash/fish/zsh 자동 시작 통합만 제공하고
  # nushell 통합은 없다. 우리 로그인 셸은 nushell 이므로 터미널을 열 때 zellij 가
  # 자동으로 뜨지 않는다 (직접 실행할 때만 띄운다) — 의도한 동작이다.
  programs.zellij = {
    enable = true;
    settings = {
      # Ghostty 와 동일한 색 테마로 통일. catppuccin-mocha 는 zellij 내장 테마라
      # 별도 테마 파일 정의가 필요 없다.
      theme = "catppuccin-mocha";
      # zellij 내부 pane 도 로그인 셸과 동일하게 nushell 을 쓰게 고정한다.
      # 안정 경로(/run/current-system/sw/bin)를 써서 store 해시 변화에 영향받지 않게 한다.
      default_shell = "/run/current-system/sw/bin/nu";
    };
  };
}
