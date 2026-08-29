{ ... }:
{
  # nix-darwin 시스템 구성의 단일 진입점.
  imports = [
    ./core.nix
    ./users.nix
    ./fonts.nix
    ./homebrew.nix
    ./karabiner.nix
  ];
}
