{ pkgs, ... }:
{
  # 사용자 패키지
  home.packages = [
    pkgs.nodejs # Node.js (현재 LTS)
  ];

  # home-manager 자기 자신을 관리
  programs.home-manager.enable = true;

  # Git
  programs.git = {
    enable = true;
    settings.user.name = "Chanhee Lee";
    settings.user.email = "contact@imch.dev";
    # git merge 자체를 squash 기본값으로 바꾸는 config 는 없으므로 alias 로 제공
    settings.alias = {
      sm = "merge --squash";
    };
  };

  # GitHub CLI
  programs.gh.enable = true;
}
