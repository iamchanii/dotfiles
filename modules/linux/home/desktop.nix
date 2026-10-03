{ lib, pkgs, ... }:
{
  # Fedora/KDE 세션이 Nix profile의 desktop entry, 아이콘, terminfo를 찾도록 한다.
  targets.genericLinux.enable = true;

  # Nix GUI 앱이 기대하는 /run/opengl-driver에 일관된 Mesa 스택을 제공한다.
  # 최초 1회 `make setup-gpu-linux`로 시스템 링크를 설치해야 한다.
  targets.genericLinux.gpu.enable = true;

  xdg.enable = true;

  # KDE가 덮개 이벤트를 처리하므로 logind 대신 PowerDevil 프로필을 설정한다.
  # 덮개/유휴 절전과 자동 잠금만 끄고 수동 동작 및 배터리 고갈 보호는 보존한다.
  home.activation.disableLidSleep = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for profile in AC Battery LowBattery; do
      run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
        --file powerdevilrc --group "$profile" --group SuspendAndShutdown \
        --key LidAction 0
      run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
        --file powerdevilrc --group "$profile" --group SuspendAndShutdown \
        --key AutoSuspendAction 0
    done
    run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
      --file kscreenlockerrc --group Daemon --key Autolock --type bool false

    # 실행 중인 KDE에도 반영해 재로그인으로 작업이 중단되지 않도록 한다.
    if [ -n "''${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
      if ${pkgs.systemd}/bin/systemctl --user is-active --quiet plasma-powerdevil.service; then
        run ${pkgs.systemd}/bin/busctl --user call \
          org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement \
          org.kde.Solid.PowerManagement refreshStatus
      fi
      if ${pkgs.systemd}/bin/busctl --user status org.freedesktop.ScreenSaver >/dev/null 2>&1; then
        run ${pkgs.systemd}/bin/busctl --user call \
          org.freedesktop.ScreenSaver /ScreenSaver org.kde.screensaver configure
      fi
    fi
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
