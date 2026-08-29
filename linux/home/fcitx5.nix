{ pkgs, ... }:
{
  home.packages = [ pkgs.qt6Packages.fcitx5-configtool ];

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

  # Fedora fcitx5-autostart가 /usr/bin/fcitx5를 별도로 띄우지 않게 하고 아래의
  # Home Manager user service가 Nix 패키지만 실행하도록 한다.
  xdg.configFile."autostart/org.fcitx.Fcitx5.desktop".text = ''
    [Desktop Entry]
    Hidden=true
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
      EnabledAddons=
      DisabledAddons=
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
      # Nix 패키지를 user service로 실행한다. Fedora의 KWin launcher는 실행 중인
      # daemon에 Wayland input-method 연결을 전달하는 용도로 계속 사용한다.
      systemd.enable = true;
      addons = with pkgs; [
        fcitx5-hangul
        fcitx5-gtk
      ];
      sessionVariables.XMODIFIERS = "@im=fcitx";
    };
  };
}
