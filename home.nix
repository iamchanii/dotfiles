{ inputs, pkgs, ... }:
{
  imports = [ inputs.nix4nvchad.homeManagerModules.default ];

  home.stateVersion = "25.11";

  # 사용자 패키지
  home.packages = [
    pkgs.nodejs # Node.js (현재 LTS)
  ];

  # home-manager 자기 자신을 관리
  programs.home-manager.enable = true;

  # NvChad (nix4nvchad). nvim 실행 파일을 래핑하므로
  # programs.neovim.enable 과 동시 사용 금지.
  programs.nvchad.enable = true;

  # GitHub CLI
  programs.gh.enable = true;

  # 기존 ~/.zshrc 의 PATH 한 줄을 선언적으로 대체한다.
  home.sessionPath = [ "$HOME/.local/bin" ];

  # zsh 를 home-manager 로 관리한다.
  # 시스템 레벨 programs.zsh(darwin.nix)는 /etc/zshrc 를 다루고,
  # 여기서는 사용자 ~/.zshrc 를 관리해 starship 통합 라인이 자동으로 들어가게 한다.
  programs.zsh.enable = true;

  # Starship 프롬프트. enableZshIntegration 이 기본 true 라서
  # ~/.zshrc 끝에 `eval "$(starship init zsh)"` 가 자동 추가된다.
  programs.starship.enable = true;

  # Ghostty 터미널.
  # 앱 바이너리(ghostty-bin)는 darwin.nix 의 systemPackages 가 설치하므로
  # 여기서는 package=null 로 두고 설정 파일(~/.config/ghostty/config)만 관리한다.
  programs.ghostty = {
    enable = true;
    package = null;
    settings = {
      theme = "Catppuccin Mocha";
      # CodexMono EA Nerd: 라틴+한글+일본어+중국어(간체) + Nerd Font 아이콘을
      # 단일 폰트로 커버하므로 폴백이 필요 없다.
      # (폰트 자체는 darwin.nix 의 fonts.packages 가 설치)
      font-family = "CodexMono EA Nerd";
      # CodexMono 는 합자(ligature)를 지원하지 않으므로 명시적으로 끈다.
      font-feature = [ "-calt" "-liga" "-dlig" ];
      font-size = 14;
      background-opacity = 0.95;
      cursor-style = "block";
      macos-option-as-alt = true;
      window-save-state = "always";
    };
  };
}
