{ inputs, ... }:
{
  # 운영체제와 무관한 Home Manager 구성의 단일 진입점.
  imports = [
    inputs.agent-skills.homeManagerModules.default
    ./cli.nix
    ./package-managers.nix
    ./shell.nix
    ./terminals.nix
    ./editor.nix
    ./agent-skills.nix
    ./npm-global-pkgs.nix
  ];
}
