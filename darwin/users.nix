{ pkgs, ... }:
{
  # 사용자 옵션 적용을 위한 primary user 지정 (최신 nix-darwin 요구사항)
  system.primaryUser = "chanhee";

  # 기존 사용자의 로그인 셸을 선언적으로 바꾸려면 nix-darwin 이 해당 사용자를
  # "관리 대상"으로 알아야 한다. knownUsers 에 넣으면 uid/shell 등을 적용한다.
  users.knownUsers = [ "chanhee" ];
  users.users.chanhee = {
    name = "chanhee";
    home = "/Users/chanhee";
    uid = 501; # 기존 계정 uid (id -u 로 확인). knownUsers 에 필요.
    shell = pkgs.nushell; # 로그인 셸을 nushell 로 변경
  };

  # nushell 을 유효한 로그인 셸로 등록한다 (/etc/shells 에 추가).
  # 시스템 zsh(/etc/zshrc)는 복구용 안전망 겸 nix 환경 로딩을 위해 그대로 둔다.
  environment.shells = [ pkgs.nushell ];
  programs.zsh.enable = true;
}
