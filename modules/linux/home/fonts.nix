{ inputs, pkgs, ... }:
let
  jetendard = import ../../shared/jetendard.nix { inherit inputs pkgs; };
in
{
  fonts.fontconfig.enable = true;
  home.packages = [ jetendard ];
}
