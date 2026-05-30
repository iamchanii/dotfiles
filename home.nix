{ inputs, pkgs, ... }:
{
  imports = [ inputs.nix4nvchad.homeManagerModules.default ];

  home.stateVersion = "25.11";
  home.packages = [ ];

  # home-manager 자기 자신을 관리
  programs.home-manager.enable = true;

  # NvChad (nix4nvchad). nvim 실행 파일을 래핑하므로
  # programs.neovim.enable 과 동시 사용 금지.
  programs.nvchad.enable = true;

  # GitHub CLI
  programs.gh.enable = true;

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
