{ ... }:
{
  # Homebrew cask 관리.
  #
  # nix-darwin 의 homebrew 모듈은 cask/formula 목록을 선언적으로 관리하지만
  # brew 바이너리 자체는 설치하지 않는다. 그래서 최초 1회 https://brew.sh 의
  # 설치 스크립트를 수동 실행해 둬야 한다 (README 설치 절차 참고).
  #
  # brew 로 설치하는 모든 것은 이 파일의 casks 에 적는다. 여기 선언되지 않은
  # cask/formula 는 cleanup="zap" 으로 제거돼 상태를 선언적으로 유지한다.
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true; # rebuild 마다 brew formulae 목록 갱신
      upgrade = true; # 선언된 cask 를 최신으로 업그레이드
      cleanup = "zap"; # 선언되지 않은 cask/formula 제거
      extraFlags = [ "--force" ]; # brew bundle --cleanup 에 필요한 확인 플래그
    };

    masApps = {
      # KakaoTalk: 카카오 메신저.
      "KakaoTalk" = 869223134;
    };

    taps = [
      # opencode formula 를 제공하는 서드파티 탭.
      "anomalyco/tap"
    ];

    brews = [
      # opencode: AI 코딩 에이전트 CLI.
      "anomalyco/tap/opencode"
    ];

    casks = [
      # Karabiner-Elements: macOS 키보드 커스터마이징. v15 부터 nix-darwin 모듈이
      # 동작하지 않아 cask 로 설치한다. 자세한 사정은 darwin/karabiner.nix 참고.
      "karabiner-elements"

      # Google Chrome: 웹 브라우저.
      "google-chrome"

      # 1Password: 비밀번호 관리자.
      "1password"

      # Obsidian: 마크다운 기반 노트 앱.
      "obsidian"
    ];
  };
}
