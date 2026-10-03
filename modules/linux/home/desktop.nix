{ lib, pkgs, ... }:
{
  # Fedora/KDE 세션이 Nix profile의 desktop entry, 아이콘, terminfo를 찾도록 한다.
  targets.genericLinux.enable = true;

  # Nix GUI 앱이 기대하는 /run/opengl-driver에 일관된 Mesa 스택을 제공한다.
  # 최초 1회 `make setup-gpu-linux`로 시스템 링크를 설치해야 한다.
  targets.genericLinux.gpu.enable = true;

  xdg.enable = true;

  # KDE가 덮개 이벤트를 처리하므로 logind 대신 PowerDevil 프로필을 설정한다.
  # 다른 전원 설정은 보존하고, 적용 후 재로그인하면 반영된다.
  home.activation.disableLidSleep = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for profile in AC Battery LowBattery; do
      run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
        --file powerdevilrc --group "$profile" --group SuspendAndShutdown \
        --key LidAction 0
    done
  '';

  home.packages = with pkgs; [
    (bun.overrideAttrs (finalAttrs: _previousAttrs: {
      version = "1.4.2";
      src = fetchurl {
        url = "https://github.com/oven-sh/bun/releases/download/bun-v${finalAttrs.version}/bun-linux-aarch64.zip";
        hash = "sha256-VDKLvC2cjgyfiSxUTWbFeoO4QTnjSQnl7oF1jxrI/ac=";
      };
    }))
    chromium
    _1password-gui
    _1password-cli
  ];
}
