{ pkgs, ... }:
{
  # 사용자 패키지
  home.packages = [
    pkgs.nodejs # Node.js (현재 LTS)
  ];

  # home-manager 자기 자신을 관리
  programs.home-manager.enable = true;

  # GitHub CLI
  programs.gh.enable = true;
}
