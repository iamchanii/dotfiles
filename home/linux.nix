{ config, inputs, pkgs, ... }:
let
  python = pkgs.python3.withPackages (ps: [ ps.brotli ps.fonttools ]);

  nerdFonts = pkgs.fetchurl {
    url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip";
    hash = "sha256-dvBf86zkikZKbKV5d5mHhP9727ZabZFdfkAc05J8STw=";
  };

  pretendard = pkgs.fetchurl {
    url = "https://github.com/orioncactus/pretendard/releases/download/v1.3.9/Pretendard-1.3.9.zip";
    hash = "sha256-BL41GnTWv31gxICjCH5R0YVIXTWlICMUKvHfGeuMQoo=";
  };

  jetendard = pkgs.stdenvNoCC.mkDerivation {
    pname = "jetendard";
    version = "0-unstable-2026-07-07";
    src = inputs.jetendard;

    nativeBuildInputs = [ pkgs.unzip python ];

    buildPhase = ''
      runHook preBuild
      mkdir -p upstream/jetbrainsmono upstream/pretendard
      unzip -j ${nerdFonts} 'JetBrainsMonoNerdFontMono-*.ttf' -d upstream/jetbrainsmono
      unzip -j ${pretendard} 'public/static/alternative/Pretendard-*.ttf' -d upstream/pretendard
      PYTHONPATH="$PWD/src" ${python}/bin/python -m jetendard.cli --all
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/share/fonts/truetype"
      cp fonts/ttf/*.ttf "$out/share/fonts/truetype/"
      runHook postInstall
    '';
  };
in
{
  imports = [ inputs.toshy.homeManagerModules.toshy ];

  # Fedora/KDE 세션이 Nix profile의 desktop entry, 아이콘, terminfo를 찾도록 한다.
  targets.genericLinux.enable = true;
  # Nix GUI 앱이 기대하는 /run/opengl-driver에 일관된 Mesa 스택을 제공한다.
  # 최초 1회 `make setup-gpu-linux`로 시스템 링크를 설치해야 한다.
  targets.genericLinux.gpu.enable = true;
  xdg.enable = true;

  fonts.fontconfig.enable = true;

  home.packages = [
    pkgs.bun
    pkgs.chromium
    pkgs._1password-gui
    pkgs._1password-cli
    pkgs.qt6Packages.fcitx5-configtool
    (pkgs.writeShellScriptBin "toshy-install-user-files" ''
      runtime="${config.home.homeDirectory}/.local/state/toshy/runtime"
      if [ ! -x "$runtime/bin/python" ]; then
        echo "Toshy runtime이 없습니다. 먼저 make switch를 실행하세요." >&2
        exit 1
      fi
      exec "$runtime/bin/python" ${inputs.toshy}/setup_toshy.py install-user-files "$@"
    '')
    (pkgs.writeShellScriptBin "toshy-apply-customizations" ''
      exec ${pkgs.python3}/bin/python ${../scripts/apply-toshy-customizations.py} "$@"
    '')
    jetendard
  ];

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

  # 공식 Flake는 런타임만 관리한다. 기존 Toshy 사용자 파일과 서비스는
  # install-user-files가 업데이트하면서 keymapper_api 구간을 보존한다.
  services.toshy.enable = true;
}
