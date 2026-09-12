{ pkgs, ... }:
{
  # Fedora/KDE 세션이 Nix profile의 desktop entry, 아이콘, terminfo를 찾도록 한다.
  targets.genericLinux.enable = true;

  # Nix GUI 앱이 기대하는 /run/opengl-driver에 일관된 Mesa 스택을 제공한다.
  # 최초 1회 `make setup-gpu-linux`로 시스템 링크를 설치해야 한다.
  targets.genericLinux.gpu.enable = true;

  xdg.enable = true;

  home.packages = with pkgs; [
    bun
    chromium
    _1password-gui
    _1password-cli
  ];
}
