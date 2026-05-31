{ ... }:
{
  # Karabiner-Elements: macOS 키보드 커스터마이징 도구.
  # nix-darwin 모듈이 앱 설치뿐 아니라 VirtualHIDDevice 드라이버(시스템 확장)와
  # grabber/observer 데몬까지 launchd 로 등록·기동해 준다.
  #
  # 최초 적용 후에는 macOS 가 요구하는 두 가지 수동 승인이 필요하다:
  #   1) 시스템 설정 > 일반 > 로그인 항목 및 확장 > 드라이버 확장 에서 활성화
  #   2) 시스템 설정 > 개인정보 보호 및 보안 > 입력 모니터링 에서
  #      karabiner_grabber / karabiner_observer 허용
  # (설정 자체는 ~/.config/karabiner 에 저장되며 GUI 또는 Goku 등으로 관리)
  services.karabiner-elements.enable = true;
}
