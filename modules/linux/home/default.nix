{ pkgs, ... }:
let
  androidSdk = (pkgs.androidenv.composeAndroidPackages {
    platformVersions = [ "34" ];
    buildToolsVersions = [ "30.0.3" ]; # Android Gradle Plugin 7.4 기본 버전
    includeEmulator = false;
    includeSystemImages = false;
    includeNDK = false;
  }).androidsdk;
in
{
  # Fedora 전용 기능은 변경 이유가 독립적인 단위로 나눈다. 이 파일은 Linux
  # 구성을 조합하는 진입점만 담당한다.
  imports = [
    ../../shared/home
    ./desktop.nix
    ./fonts.nix
    ./theme.nix
    ./fcitx5.nix
    ./toshy.nix
    ./flameshot.nix
  ];

  # Books App의 Gradle 8.2 / Android JDK 11 툴체인에 맞춘다.
  programs.java = {
    enable = true;
    package = pkgs.jdk11;
  };
  home.packages = [ pkgs.android-tools ]; # Fedora ARM64에서 실행할 adb
  home.sessionVariables.ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
}
