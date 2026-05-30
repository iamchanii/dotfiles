{ pkgs, ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Nix 자체 관리는 Determinate Nix 에 위임한다.
  # determinateNix.enable = true 가 nix-darwin 의 내장 Nix 설정을 비활성화하므로
  # 여기서 nix.* 를 직접 설정하지 않는다.
  determinateNix.enable = true;

  # 사용자 옵션 적용을 위한 primary user 지정 (최신 nix-darwin 요구사항)
  system.primaryUser = "chanhee";
  users.users.chanhee = {
    name = "chanhee";
    home = "/Users/chanhee";
  };

  # zsh 를 기본 셸로 사용
  programs.zsh.enable = true;

  # macOS 시스템 기본값
  system.defaults.NSGlobalDomain = {
    # 키보드 입력 반복 속도 개선
    KeyRepeat = 1; # 반복 속도 (최소값 = 가장 빠름)
    InitialKeyRepeat = 10; # 반복 시작 전 지연 (최소값 = 가장 짧음)
    ApplePressAndHoldEnabled = false; # 길게 누르면 액센트 메뉴 대신 반복 입력
  };

  # 최소 시스템 패키지 (필요 시 확장)
  environment.systemPackages = [ ];

  # nix-darwin 상태 버전 (한번 정하면 변경하지 말 것).
  # 현재 nix-darwin 의 maxStateVersion 이자 신규 설치 기본값.
  # 6→7 의 유일한 동작 차이는 programs.tmux.enableSensible 기본값(<=6 이면 켜짐)
  # 이며, tmux 를 nix-darwin 으로 관리하지 않는 이 구성에선 영향이 없다.
  system.stateVersion = 7;
}
