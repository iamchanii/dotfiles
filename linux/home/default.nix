{ ... }:
{
  # Fedora 전용 기능은 변경 이유가 독립적인 단위로 나눈다. 이 파일은 Linux
  # 구성을 조합하는 진입점만 담당한다.
  imports = [
    ../../common/home/default.nix
    ./desktop.nix
    ./fonts.nix
    ./theme.nix
    ./fcitx5.nix
    ./toshy.nix
  ];
}
