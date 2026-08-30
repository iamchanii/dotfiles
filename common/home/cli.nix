{ inputs, lib, pkgs, ... }:
{
  # 사용자 패키지
  home.packages =
    [
      pkgs.nodejs # Node.js (현재 LTS)
      pkgs.gh # 설정 파일은 GitHub CLI가 직접 관리
      inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
    ]
    # uv 는 기존 Mac 구성에만 유지한다.
    ++ lib.optionals pkgs.stdenv.isDarwin [ pkgs.uv ];

  # home-manager 자기 자신을 관리
  programs.home-manager.enable = true;

  # Git
  programs.git = {
    enable = true;
    settings.user.name = "Chanhee Lee";
    settings.user.email = "contact@imch.dev";
    # git init 시 기본 브랜치를 main 으로 설정
    settings.init.defaultBranch = "main";
    # Git 설정은 읽기 전용으로 생성되므로 gh auth setup-git 대신 선언적으로 관리한다.
    settings.credential."https://github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
    # git merge 자체를 squash 기본값으로 바꾸는 config 는 없으므로 alias 로 제공
    settings.alias = {
      sm = "merge --squash";
    };
  };
}
