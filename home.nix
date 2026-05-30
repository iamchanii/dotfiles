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
}
