{ pkgs, ... }:
let
  # GalmuriMono11: 한글 픽셀 폰트. 영문은 JetBrains Mono 를 사용하고
  # 한글 글리프는 이 폰트로 폴백한다.
  galmuri-mono11 = pkgs.runCommand "galmuri-mono11" { } ''
    mkdir -p $out/share/fonts/truetype
    cp ${pkgs.fetchurl {
      url = "https://github.com/quiple/galmuri/raw/refs/heads/main/dist/GalmuriMono11.ttf";
      hash = "sha256-I4DpzIPgOnH2q+y9vK0iYGHjSDrhnUJl8oeX1L5zwuU=";
    }} $out/share/fonts/truetype/GalmuriMono11.ttf
  '';
in
{
  # 사용자 정의 폰트. fonts.packages 에 넣으면 nix-darwin 이 share/fonts 아래
  # 파일을 /Library/Fonts/Nix Fonts 로 링크해 전역(Ghostty 포함)에서 쓸 수 있다.
  fonts.packages = [
    pkgs.jetbrains-mono  # 영문 폰트
    galmuri-mono11       # 한글 폰트
  ];
}
