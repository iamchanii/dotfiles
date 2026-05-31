{ inputs, ... }:
{
  imports = [
    inputs.agent-skills.homeManagerModules.default
    ./home/cli.nix
    ./home/package-managers.nix
    ./home/shell.nix
    ./home/terminals.nix
    ./home/editor.nix
    ./home/karabiner.nix
    ./home/agent-skills.nix
  ];

  home.stateVersion = "25.11";
}
