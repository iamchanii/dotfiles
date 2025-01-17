{ pkgs, inputs, ... }:

let
  home = inputs.home-manager.users.ette;
in
{
  homebrew.casks = import ../../casks.nix ++ [
    "slack"
    "google-chrome"
    "1password"
    "orbstack"
  ];

  homebrew.taps = import ../../taps.nix ++ [];

  homebrew.brews = import ../../brews.nix ++ [];
}
