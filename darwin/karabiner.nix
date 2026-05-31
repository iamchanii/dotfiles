{ ... }:
{
  # Karabiner-Elements: macOS 키보드 커스터마이징 도구.
  #
  # 설치는 Homebrew cask 로 한다 (darwin/homebrew.nix). nix-darwin 의
  # services.karabiner-elements 모듈은 Karabiner v15 부터 동작하지 않는다.
  # v15 에서 데몬 구조가 Core-Service 로 전면 교체되면서 모듈이 띄우려는
  # karabiner_grabber / karabiner_observer 바이너리와 LaunchAgents plist 경로가
  # 모두 사라졌기 때문이다. (참고: nix-darwin#1041, #1132)
  #
  # 키맵은 home/karabiner.nix 가 karabiner.json 으로 선언적으로 생성한다.
  #
  # 최초 적용 후 macOS 가 요구하는 수동 승인:
  #   시스템 설정 > 일반 > 로그인 항목 및 확장 > 드라이버 확장 에서 활성화
  #   시스템 설정 > 개인정보 보호 및 보안 > 입력 모니터링 허용
}
