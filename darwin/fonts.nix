{ pkgs, ... }:
let
  # CodexMono v1.0.5 릴리스 zip 에서 EA Nerd 변형만 추출해 패키징한다.
  # EA(East Asia) 가 라틴/한글/일본어/중국어(간체)를 모두 커버하고,
  # Nerd 빌드는 여기에 터미널 심볼(Nerd Font 아이콘)까지 포함하므로
  # 별도 폴백 없이 단일 폰트로 쓴다. (plain/Hermes 변형은 제외)
  codexmonoSrc = pkgs.fetchzip {
    url = "https://github.com/monolex/codexmono/archive/refs/tags/v1.0.5.zip";
    hash = "sha256-WJLgKYbZ98roOnzYEKki/ESwVSIz8DLB+QJykKGB/L4=";
  };
  codexmono-ea = pkgs.runCommand "codexmono-ea-nerd-1.0.5" { } ''
    mkdir -p $out/share/fonts/truetype
    cp ${codexmonoSrc}/fonts/nerd/ttf/CodexMono-EA-Nerd.ttf $out/share/fonts/truetype/
  '';
in
{
  # 사용자 정의 폰트. fonts.packages 에 넣으면 nix-darwin 이 share/fonts 아래
  # 파일을 /Library/Fonts/Nix Fonts 로 링크해 전역(Ghostty 포함)에서 쓸 수 있다.
  fonts.packages = [ codexmono-ea ];
}
