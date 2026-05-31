{ ... }:
{
  # Karabiner-Elements: macOS 키보드 커스터마이징 도구.
  #
  # nix-darwin 의 services.karabiner-elements 모듈은 Karabiner v15 부터
  # 동작하지 않는다. v15 에서 데몬 구조가 Core-Service 로 전면 교체되면서
  # 모듈이 띄우려는 karabiner_grabber / karabiner_observer 바이너리와
  # LaunchAgents plist 경로가 모두 사라졌기 때문이다.
  # (참고: nix-darwin#1041, #1132)
  #
  # 그래서 v15 의 드라이버(시스템 확장)·데몬 설치를 네이티브로 처리해 주는
  # Homebrew cask 로 설치한다. nix-darwin 의 homebrew 모듈은 brew 바이너리를
  # 직접 설치하진 않으므로, 최초 1회 https://brew.sh 의 설치 스크립트를
  # 수동 실행해 둬야 한다.
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true; # rebuild 마다 brew formulae 목록 갱신
      upgrade = true; # 선언된 cask 를 최신으로 업그레이드
      # 여기 선언되지 않은 cask/formula 는 제거해 상태를 선언적으로 유지한다.
      # 즉 brew 로 설치하는 모든 것은 이 파일에 적어야 한다.
      cleanup = "zap";
    };

    casks = [ "karabiner-elements" ];
  };

  # 최초 적용 후 macOS 가 요구하는 수동 승인:
  #   시스템 설정 > 일반 > 로그인 항목 및 확장 > 드라이버 확장 에서 활성화
  #   시스템 설정 > 개인정보 보호 및 보안 > 입력 모니터링 허용
}
