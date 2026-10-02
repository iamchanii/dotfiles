{ pkgs, ... }:
{
  # 공식 다운로드 페이지가 안내하는 `nix-env -iA nixos.flameshot` 대신 Home
  # Manager 프로파일에 넣어 세대 관리와 롤백을 따른다.
  home.packages = [ pkgs.flameshot ];

  # 로그인 시 데몬을 띄워 트레이 아이콘과 `flameshot gui` 호출(D-Bus 활성화)을
  # 바로 쓸 수 있게 한다. upstream "launch at startup" 토글이 만드는 파일과 같은
  # 위치에 같은 내용을 선언하므로 GUI의 자동 시작 토글은 사용하지 않는다.
  xdg.configFile."autostart/flameshot.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Flameshot
    GenericName=Screenshot tool
    Comment=Capture, annotate and share screenshots
    Icon=org.flameshot.Flameshot
    Exec=${pkgs.flameshot}/bin/flameshot
    Terminal=false
    Categories=Utility;
    X-GNOME-Autostart-enabled=true
  '';

  # 설정 파일(~/.config/flameshot/flameshot.ini)은 앱이 직접 다시 쓰므로 Home
  # Manager가 관리하지 않는다. 색상·저장 경로 등은 `flameshot config`에서 바꾼다.
  # KDE 전역 단축키(Print 등)도 시스템 설정에서 명령 `flameshot gui`에 직접
  # 연결한다.
}
