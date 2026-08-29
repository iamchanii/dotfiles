{ config, lib, pkgs, ... }:

let
  npmGlobalDir = "${config.home.homeDirectory}/.npm-global";
  # 전역으로 설치할 npm 패키지 목록.
  # nixpkg node 는 store 가 읽기 전용이라 -g 설치가 실패하므로 여기서 관리한다.
  npmGlobalPackages = [
    "defuddle"
  ];
in
{
  # ~/.npm-global/bin 을 PATH 에 추가한다.
  # shell.nix 의 extraEnv 이후에 합산(types.lines 연결)되므로 $env.PATH 는 이미 list.
  programs.nushell.extraEnv = ''
    $env.PATH = (
      $env.PATH
      | (if ($in | describe) == "string" { split row (char esep) } else { $in })
      | prepend ["${npmGlobalDir}/bin"]
      | uniq
    )
  '';

  # home-manager switch 시 누락된 패키지만 설치한다.
  # 바이너리 존재 여부로 설치 여부를 판단해 불필요한 네트워크 요청을 막는다.
  home.activation.installNpmGlobalPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${npmGlobalDir}"
    ${lib.concatMapStrings (pkg: ''
      if [[ ! -e "${npmGlobalDir}/bin/${pkg}" ]]; then
        run "${pkgs.nodejs}/bin/npm" install -g --prefix "${npmGlobalDir}" "${pkg}"
      fi
    '') npmGlobalPackages}
  '';
}
