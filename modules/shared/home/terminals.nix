{ config, inputs, lib, pkgs, ... }:
{
  # Ghostty 터미널.
  # 앱 바이너리(ghostty-bin)는 modules/darwin/system/core.nix 의 systemPackages가 설치하므로
  # 여기서는 package=null 로 두고 설정 파일(~/.config/ghostty/config)만 관리한다.
  programs.ghostty = {
    enable = true;
    package =
      if pkgs.stdenv.isDarwin then
        null
      else
        inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default;
    settings = {
      # Ghostty 는 기본적으로 $SHELL 환경변수를 따르는데, macOS GUI 로그인 세션의
      # $SHELL 은 로그인 시점 값(/bin/zsh)으로 캐시돼 dscl 로 셸을 바꿔도 재로그인
      # 전까지 갱신되지 않는다. 그래서 셸을 nushell 로 명시해 즉시·확실하게 고정한다.
      # Home Manager 활성 프로파일을 사용해 세대 변경 후에도 현재 Nushell을 실행한다.
      command = "${config.home.profileDirectory}/bin/nu";
      theme = "Catppuccin Mocha";
      # 두 플랫폼 모두 modules/shared/jetendard.nix 에서 만든 한영 고정폭 폰트를 쓴다.
      font-family = "Jetendard";
      font-feature = [ "-calt" "-liga" "-dlig" ];
      font-size = 12;
      # 기존 Mac 투명도는 유지하고 Fedora에서만 불투명 배경을 쓴다.
      background-opacity = lib.mkIf pkgs.stdenv.isDarwin 0.95;
      cursor-style = "block";
      macos-option-as-alt = lib.mkIf pkgs.stdenv.isDarwin true;
      window-save-state = "always";
    };
  };

  # Zellij 터미널 멀티플렉서 (macOS/Fedora 공통).
  # home-manager 의 zellij 모듈은 bash/fish/zsh 자동 시작 통합만 제공하고
  # nushell 통합은 없다. 우리 로그인 셸은 nushell 이므로 터미널을 열 때 zellij 가
  # 자동으로 뜨지 않는다 (z 또는 zellij 로 직접 실행) — 의도한 동작이다.
  programs.zellij = {
    enable = true;
    # 메인 nixpkgs(0.44.3) 와 별개로 0.45.1 을 담은 리비전에서 가져온다.
    # Ghostty 입력 참조와 같은 모양이다.
    package = inputs.nixpkgs-zellij.legacyPackages.${pkgs.stdenv.hostPlatform.system}.zellij;
    settings = {
      # Ghostty 와 동일한 색 테마로 통일. catppuccin-mocha 는 zellij 내장 테마라
      # 별도 테마 파일 정의가 필요 없다.
      theme = "catppuccin-mocha";
      # zellij 내부 pane 도 로그인 셸과 동일하게 nushell 을 쓰게 고정한다.
      # store 해시가 아닌 안정 프로파일 경로를 쓴다: macOS 는 nix-darwin 시스템
      # 프로파일(/run/current-system/sw/bin), Fedora 는 standalone Home Manager
      # 프로파일(shell.nix 의 PATH 와 동일한 home.profileDirectory).
      default_shell = if pkgs.stdenv.isDarwin then
        "/run/current-system/sw/bin/nu"
      else
        "${config.home.profileDirectory}/bin/nu";
    } // lib.optionalAttrs pkgs.stdenv.isLinux {
      # Zorca 플러그인/레이아웃은 Fedora 홈에만 설치한다.
      default_layout = "zorca";
    };
  };
}
