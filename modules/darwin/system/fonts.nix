{ inputs, pkgs, ... }:
let
  jetendard = import ../../shared/jetendard.nix { inherit inputs pkgs; };
in
{
  # nix-darwin 이 share/fonts 아래 파일을 /Library/Fonts/Nix Fonts 로 링크해
  # Ghostty를 포함한 전역 앱에서 Fedora와 동일한 Jetendard를 사용할 수 있게 한다.
  fonts.packages = [ jetendard ];
}
