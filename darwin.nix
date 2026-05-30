{ pkgs, ... }:
let
  # CodexMono v1.0.5 릴리스 zip 에서 EA Nerd 변형만 추출해 패키징한다.
  # EA(East Asia) 가 라틴/한글/일본어/중국어(간체)를 모두 커버하고,
  # Nerd 빌드는 여기에 터미널 심볼(Nerd Font 아이콘)까지 포함하므로
  # 별도 폴백 없이 단일 폰트로 쓴다. (plain/Hermes 변형은 제외)
  codexmonoSrc = pkgs.fetchzip {
    url = "https://github.com/monolex/codexmono/archive/refs/tags/v1.0.5.zip";
    hash = "sha256-WJLgKYbZ98roOnzYEKki/ESwVSIz8DLB+QJykKGB/L4=";
  };
  codexmono-ea = pkgs.runCommand "codexmono-ea-nerd-1.0.5" { } ''
    mkdir -p $out/share/fonts/truetype
    cp ${codexmonoSrc}/fonts/nerd/ttf/CodexMono-EA-Nerd.ttf $out/share/fonts/truetype/
  '';
in
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
    KeyRepeat = 2; # 반복 속도 (최소값 = 가장 빠름)
    InitialKeyRepeat = 15; # 반복 시작 전 지연 (최소값 = 가장 짧음)
    ApplePressAndHoldEnabled = false; # 길게 누르면 액센트 메뉴 대신 반복 입력
  };

  # 최소 시스템 패키지 (필요 시 확장)
  # ghostty: nixpkgs 의 소스 빌드(pkgs.ghostty)는 Linux 전용이라 darwin 에선
  # 공식 바이너리를 재포장한 pkgs.ghostty-bin 을 사용한다.
  # systemPackages 로 설치하면 nix-darwin 이 /Applications/Nix Apps 에 링크해 준다.
  # (설정 파일은 home-manager 의 programs.ghostty 가 관리)
  environment.systemPackages = [ pkgs.ghostty-bin ];

  # 사용자 정의 폰트. fonts.packages 에 넣으면 nix-darwin 이 share/fonts 아래
  # 파일을 /Library/Fonts/Nix Fonts 로 링크해 전역(Ghostty 포함)에서 쓸 수 있다.
  fonts.packages = [ codexmono-ea ];

  # nix-darwin 상태 버전 (한번 정하면 변경하지 말 것).
  # 현재 nix-darwin 의 maxStateVersion 이자 신규 설치 기본값.
  # 6→7 의 유일한 동작 차이는 programs.tmux.enableSensible 기본값(<=6 이면 켜짐)
  # 이며, tmux 를 nix-darwin 으로 관리하지 않는 이 구성에선 영향이 없다.
  system.stateVersion = 7;
}
