{ inputs, ... }:
{
  # nix-darwin 시스템 구성의 단일 진입점.
  imports = [
    inputs.determinate.darwinModules.default
    ./core.nix
    ./users.nix
    ./fonts.nix
    ./homebrew.nix
    ./karabiner.nix
  ];
}
