{ config, lib, pkgs, ... }:

let
  # npm 전역 설치 루트. package-managers.nix 의 programs.npm.settings.prefix 가
  # 단일 소스이며, npmrc 생성(HM npm 모듈)·아래 activation·sessionPath 가
  # 모두 같은 값을 쓴다.
  npmPrefix = config.programs.npm.settings.prefix;

  # 전역으로 설치할 npm 패키지 목록.
  # nixpkgs node 는 store 가 읽기 전용이라 -g 설치가 실패하므로 여기서 관리한다.
  npmGlobalPackages = [
    "defuddle"
  ];
in
{
  # npmrc와 activation이 사용하는 전역 prefix를 공통 세션 경로에도 등록한다.
  home.sessionPath = [
    "${npmPrefix}/bin"
  ];

  # home-manager switch 시 누락된 패키지만 설치한다.
  # 바이너리 존재 여부로 설치 여부를 판단해 불필요한 네트워크 요청을 막는다.
  home.activation.installNpmGlobalPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${npmPrefix}"
    ${lib.concatMapStrings (pkg: ''
      if [[ ! -e "${npmPrefix}/bin/${pkg}" ]]; then
        run "${pkgs.nodejs}/bin/npm" install -g --prefix "${npmPrefix}" "${pkg}"
      fi
    '') npmGlobalPackages}
  '';
}
