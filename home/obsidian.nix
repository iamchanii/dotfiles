{ config, ... }:
{
  # Obsidian CLI 심링크 구성.
  #
  # Obsidian.app 번들 안에는 `obsidian-cli` 바이너리가 들어 있다. 터미널에서
  # `obsidian` 명령으로 쓰려면 PATH 에 있는 위치로 심링크를 걸어야 한다.
  #
  # 공식 안내(https://obsidian.md/help/cli#macOS)는 /usr/local/bin 을 쓰지만,
  # 이 구성의 로그인 셸인 nushell 은 macOS path_helper(/etc/paths)를 거치지 않아
  # /usr/local/bin 이 PATH 에 없다(home/shell.nix 참고). 대신 home-manager 가
  # PATH 에 넣어주는 ~/.local/bin 으로 링크해 sudo 없이 선언적으로 관리한다.
  #
  # 앱 자체는 darwin/homebrew.nix 의 cask 로 설치된다. mkOutOfStoreSymlink 는
  # nix store 밖(여기선 /Applications)의 절대 경로를 가리키는 심링크를 만든다.
  home.file.".local/bin/obsidian".source =
    config.lib.file.mkOutOfStoreSymlink
      "/Applications/Obsidian.app/Contents/MacOS/obsidian-cli";
}
