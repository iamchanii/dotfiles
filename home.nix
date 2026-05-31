{ ... }:
{
  imports = [
    ./home/cli.nix
    ./home/package-managers.nix
    ./home/shell.nix
    ./home/terminals.nix
    ./home/editor.nix
  ];

  home.stateVersion = "25.11";
}
