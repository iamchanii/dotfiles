{ inputs, user, ... }:
{
  imports = [
    inputs.agent-skills.homeManagerModules.default
    ./home/cli.nix
    ./home/package-managers.nix
    ./home/shell.nix
    ./home/terminals.nix
    ./home/editor.nix
    ./home/agent-skills.nix
    ./home/npm-global-pkgs.nix
    ./home/linux.nix
  ];

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = "25.11";
  };
}
