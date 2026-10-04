{ config, lib, pkgs, ... }:
let
  nixProfile = "/nix/var/nix/profiles/default";
  searchVariables = lib.unique (
    builtins.attrNames config.home.sessionSearchVariables
    ++ [ "PATH" "XDG_DATA_DIRS" "TERMINFO_DIRS" "MANPATH" ]
  );
  sessionVariables = lib.unique (
    builtins.attrNames (lib.filterAttrs (_: value: value != null) config.home.sessionVariables)
    ++ searchVariables
    ++ [ "NIX_PROFILES" "NIX_SSL_CERT_FILE" ]
  );
  # POSIX 전개를 재구현하지 않고 Home Manager와 기존 Nix 초기화를 재사용한다.
  # 가드는 자식 프로세스에서만 해제해 오래된 부모 환경의 영향을 받지 않는다.
  sessionLoader = pkgs.writeShellScript "nushell-session-environment" ''
    set -e
    unset __HM_SESS_VARS_SOURCED __ETC_PROFILE_NIX_SOURCED
    . "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh" >&2
    if [ -r "${nixProfile}/etc/profile.d/nix-daemon.sh" ]; then
      . "${nixProfile}/etc/profile.d/nix-daemon.sh" >&2
    fi
    for name in ${lib.escapeShellArgs sessionVariables}; do
      if [[ -v "$name" ]]; then
        printf '%s=%s\0' "$name" "''${!name}"
      fi
    done
  '';
  sessionEnv = pkgs.writeText "session-env.nu" (
    lib.replaceStrings
      [ "@bash@" "@loader@" "@searchVars@" ]
      (map (lib.hm.nushell.toNushell { }) [
        "${pkgs.bash}/bin/bash"
        (toString sessionLoader)
        searchVariables
      ])
      (builtins.readFile ../../../scripts/session-env.nu)
  );
in
{
  # 경로는 한 번 선언하고 POSIX 셸과 Nushell이 같은 Home Manager 값을 사용한다.
  home.sessionPath = [
    "${config.home.profileDirectory}/bin"
    "${nixProfile}/bin"
    "${config.home.homeDirectory}/.local/bin"
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    "/run/current-system/sw/bin"
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];
  home.sessionVariables = lib.optionalAttrs pkgs.stdenv.isDarwin {
    HOMEBREW_PREFIX = "/opt/homebrew";
    HOMEBREW_CELLAR = "/opt/homebrew/Cellar";
    HOMEBREW_REPOSITORY = "/opt/homebrew";
  };
  # nushell 을 home-manager 로 관리한다. macOS 에서는
  # ~/Library/Application Support/nushell/{env,config}.nu 가 선언적으로 생성된다.
  # 로그인 셸 지정은 modules/darwin/system/users.nix 에서 한다.
  #
  # env.nu에서 공통 세션 환경을 읽으므로 터미널/로그인 방식에 의존하지 않는다.
  # 상속한 PATH 순서를 유지하고 누락 경로만 보충해 nix develop 등도 보존한다.
  programs.nushell = {
    enable = true;
    settings = {
      show_banner = false; # 셸 시작 시 환영 배너 숨김
    };
    shellAliases = {
      vim = "nvim";
      z = "zellij";
    };
    extraEnv = ''
      source ${sessionEnv}
    '';
  };

  # Starship 프롬프트.
  # enableNushellIntegration 이 기본 true 라서, nushell 이 켜져 있으면
  # nushell config 에 starship init 통합 스크립트가 자동으로 삽입된다.
  # (https://www.nushell.sh/book/3rdpartyprompts.html 의 수동 설정을 대체)
  programs.starship.enable = true;
}
