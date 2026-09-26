{ config, inputs, lib, pkgs, ... }:
let
  fcitxPkgs = import inputs.nixpkgs-fcitx {
    inherit (pkgs) system;
  };
  fcitxPackage = config.i18n.inputMethod.package;
in
{
  # KDE Wayland에서는 KWin의 input-method frontend를 쓰고 XWayland용 XIM만
  # 유지한다. Fedora의 /etc/profile.d/fcitx5.sh가 설정한 툴킷 변수를 덮는다.
  xdg.configFile."plasma-workspace/env/fcitx5-wayland.sh" = {
    force = true;
    executable = true;
    text = ''
      unset GTK_IM_MODULE
      unset QT_IM_MODULE
      unset SDL_IM_MODULE
      export XMODIFIERS='@im=fcitx'
    '';
  };

  # Fedora fcitx5-autostart가 /usr/bin/fcitx5를 별도로 띄우지 않게 한다.
  # KDE Wayland에서는 KWin launcher가 Nix의 Fcitx를 D-Bus로 활성화한다.
  xdg.configFile."autostart/org.fcitx.Fcitx5.desktop".text = ''
    [Desktop Entry]
    Hidden=true
  '';

  # Fedora launcher 패키지를 제거해도 KWin이 사용할 수 있는 Nix launcher를 둔다.
  xdg.dataFile."applications/fcitx5-wayland-launcher.desktop".text = ''
    [Desktop Entry]
    Name=Fcitx 5 Wayland Launcher
    Exec=${fcitxPackage}/libexec/fcitx5-wayland-launcher --reopen
    Icon=fcitx
    Terminal=false
    Type=Application
    Categories=System;Utility;
    StartupNotify=false
    NoDisplay=true
    OnlyShowIn=KDE
    X-KDE-StartupNotify=false
    X-KDE-Wayland-VirtualKeyboard=true
    X-KDE-Wayland-Interfaces=org_kde_plasma_window_management
  '';

  # Fcitx의 나머지 conf 파일은 GUI가 계속 관리할 수 있도록 두 파일만 선언한다.
  xdg.configFile."fcitx5/config" = {
    force = true;
    text = ''
      [Hotkey]
      EnumerateWithTriggerKeys=True
      EnumerateSkipFirst=False

      [Hotkey/TriggerKeys]
      0=Hangul

      [Behavior]
      ActiveByDefault=False
      ShareInputState=No
      PreeditEnabledByDefault=True
      ShowInputMethodInformation=True
      showInputMethodInformationWhenFocusIn=False
      CompactInputMethodInformation=True
      ShowFirstInputMethodInformation=True
      DefaultPageSize=5
      OverrideXkbOption=False
      CustomXkbOption=
      PreloadInputMethod=True
    '';
  };

  xdg.configFile."fcitx5/profile" = {
    force = true;
    text = ''
      [Groups/0]
      Name=기본값
      Default Layout=us
      DefaultIM=hangul

      [Groups/0/Items/0]
      Name=keyboard-us
      Layout=

      [Groups/0/Items/1]
      Name=hangul
      Layout=us

      [GroupOrder]
      0=기본값
    '';
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      fcitx5-with-addons = fcitxPkgs.qt6Packages.fcitx5-with-addons;
      addons = with fcitxPkgs; [
        fcitx5-hangul
        fcitx5-gtk
      ];
    };
  };

  # KDE Wayland에서는 KWin launcher 하나만 daemon을 활성화해야 한다.
  systemd.user.services.fcitx5-daemon.Install.WantedBy = lib.mkForce [ ];

  home.activation.selectNixFcitxKwinLauncher = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
      --file kwinrc --group Wayland --key 'InputMethod[$e]' --delete
    ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
      --file kwinrc --group Wayland --key InputMethod --type path \
      '${config.home.homeDirectory}/.local/share/applications/fcitx5-wayland-launcher.desktop'
  '';
}
