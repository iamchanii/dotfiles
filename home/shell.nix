{ config, ... }:
{
  # nushell 을 home-manager 로 관리한다. macOS 에서는
  # ~/Library/Application Support/nushell/{env,config}.nu 가 선언적으로 생성된다.
  # 로그인 셸 지정은 darwin/users.nix 에서 한다.
  #
  # PATH 주의: zsh/bash 와 달리 nushell 은 Determinate Nix / nix-darwin 의 셸
  # 초기화 스니펫(/etc/zshrc 등)을 읽지 않고, home-manager 의 home.sessionPath
  # (POSIX hm-session-vars.sh)도 source 하지 않는다. 따라서 그 스니펫들이
  # 넣어주던 nix 관련 경로를 nushell env.nu 에서 직접 PATH 에 추가해야 한다.
  # extraEnv 는 env.nu 로 들어가며 config.nu(starship 통합)보다 먼저 로드된다.
  programs.nushell = {
    enable = true;
    shellAliases = {
      vim = "nvim";
      z = "zellij";
    };
    extraEnv = ''
      $env.PATH = (
        $env.PATH
        | (if ($in | describe) == "string" { split row (char esep) } else { $in })
        | prepend [
            "${config.home.profileDirectory}/bin" # home-manager 패키지 (starship 등)
            "/run/current-system/sw/bin"           # nix-darwin 시스템 패키지 (darwin-rebuild 등)
            "/nix/var/nix/profiles/default/bin"     # Determinate Nix (nix)
            "${config.home.homeDirectory}/.local/bin"
        ]
        | uniq
      )
    '';
  };

  # Starship 프롬프트.
  # enableNushellIntegration 이 기본 true 라서, nushell 이 켜져 있으면
  # nushell config 에 starship init 통합 스크립트가 자동으로 삽입된다.
  # (https://www.nushell.sh/book/3rdpartyprompts.html 의 수동 설정을 대체)
  programs.starship.enable = true;
}
