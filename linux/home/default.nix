{ config, pkgs, ... }:
{
  # Fedora 전용 기능은 변경 이유가 독립적인 단위로 나눈다. 이 파일은 Linux
  # 구성을 조합하는 진입점만 담당한다.
  imports = [
    ../../common/home/default.nix
    ./desktop.nix
    ./fonts.nix
    ./theme.nix
    ./fcitx5.nix
    ./toshy.nix
  ];

  # Books App의 Gradle 8.2 / Android JDK 11 툴체인에 맞춘다.
  programs.java = {
    enable = true;
    package = pkgs.jdk11;
  };
  # Nushell은 Home Manager의 POSIX 세션 변수 스크립트를 읽지 않는다.
  programs.nushell.environmentVariables.JAVA_HOME = config.home.sessionVariables.JAVA_HOME;
}
