{ ... }:
{
  # macOS에서만 사용하는 Home Manager 구성.
  imports = [
    ../../common/home/default.nix
    ./obsidian.nix
    ./karabiner.nix
  ];

  home.stateVersion = "25.11";
}
