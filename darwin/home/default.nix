{ config, pkgs, ... }:
let
  # 고정된 nixpkgs의 Temurin 26.0.1 대신 최신 안정판 보안 업데이트를 사용한다.
  jdk = pkgs.temurin-bin-26.overrideAttrs {
    version = "26.0.2.1";
    src = pkgs.fetchurl {
      url = "https://github.com/adoptium/temurin26-binaries/releases/download/jdk-26.0.2.1%2B1/OpenJDK26U-jdk_aarch64_mac_hotspot_26.0.2.1_1.tar.gz";
      sha256 = "8c77a069a150c5b1c80280269ba062463053ebb7619ddef38dcfe3921fc60bdd";
    };
  };
  androidSdk = (pkgs.androidenv.composeAndroidPackages {
    cmdLineToolsVersion = "20.0";
    platformToolsVersion = "37.0.0";
    buildToolsVersions = [ "37.0.0" ];
    platformVersions = [ "37.0" ];
    # 실기기 ADB와 기본 빌드 도구만 설치한다. 구형 tools와 CMake는 제외한다.
    toolsVersion = null;
    includeCmake = false;
  }).androidsdk;
in
{
  # macOS에서만 사용하는 Home Manager 구성.
  imports = [
    ../../common/home/default.nix
    ./obsidian.nix
    ./karabiner.nix
  ];

  home.stateVersion = "25.11";

  programs.java = {
    enable = true;
    package = jdk;
  };
  home.packages = [ androidSdk ];
  home.sessionVariables.ANDROID_HOME = "${androidSdk}/libexec/android-sdk";

  # Nushell은 Home Manager의 POSIX 세션 변수 스크립트를 읽지 않는다.
  programs.nushell.environmentVariables = {
    inherit (config.home.sessionVariables) JAVA_HOME ANDROID_HOME;
  };
}
