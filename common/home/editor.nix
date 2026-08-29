{ inputs, ... }:
{
  imports = [ inputs.nix4nvchad.homeManagerModules.default ];

  # NvChad (nix4nvchad). nvim 실행 파일을 래핑하므로
  # programs.neovim.enable 과 동시 사용 금지.
  programs.nvchad.enable = true;
}
