{ ... }:
{
  # 패키지 매니저 쿨다운(최소 릴리스 경과 시간) = 1일.
  # 갓 게시돼 아직 검증되지 않은 버전의 설치를 하루 지연시켜, npm 공급망 공격
  # (악성 버전이 게시 후 수 시간~수 일 내 적발·삭제되는 패턴)을 방어한다.
  # 네 메이저 PM 모두 네이티브 지원하지만 키·파일·단위가 제각각이라 따로 적는다.
  #
  # 주의: 아래 파일들은 home-manager 가 nix store 로의 (읽기 전용) 심링크로 만들므로
  # npm login 등 ~/.npmrc 에 쓰는 작업은 프로젝트 .npmrc 나 환경변수로 처리해야 한다.

  # npm (>=11.10): min-release-age. 단위는 "일"이고 값은 정수만 허용
  # (`1d`/`24h` 같은 문자열은 거부됨). 1일 = 1.
  home.file.".npmrc".text = ''
    min-release-age=1
  '';

  # pnpm (>=11): minimumReleaseAge, 분 단위. pnpm 11 부터 이 설정은 .npmrc 가 아닌
  # 전역 YAML 설정(~/.config/pnpm/config.yaml)에서 읽는다. 1일 = 1440분.
  xdg.configFile."pnpm/config.yaml".text = ''
    minimumReleaseAge: 1440
  '';

  # yarn (berry >=4.10): npmMinimalAgeGate, 분 단위. `1d` 문자열은 day 접미사가
  # 무시되는 버그가 있어 분으로 명시한다. 1일 = 1440분.
  home.file.".yarnrc.yml".text = ''
    npmMinimalAgeGate: 1440
  '';

  # bun (>=1.3): [install].minimumReleaseAge, 초 단위. 1일 = 86400초.
  home.file.".bunfig.toml".text = ''
    [install]
    minimumReleaseAge = 86400
  '';
}
