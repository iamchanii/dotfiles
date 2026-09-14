# agent-skills 소스 선택과 OMP 검색 경로 조사

조사일: 2026-09-14. 설정 변경 없이 고정된 입력과 Nix 평가로 확인했다.

## 결론

`filter.mapDpeth`가 아니라 `sources.<name>.filter.maxDepth`가 정확한 옵션 이름이다.
이 옵션은 **탐색 깊이의 상한**이며, 디렉터리 제거·이름 변경·번들 평탄화 옵션이 아니다.
현재 소스에서 `maxDepth = 1`만 추가하면 37개 스킬이 평탄화되는 것이 아니라 카탈로그가 비게 된다.

현재 `skill.source == "mattpocock"` 분기를 없애는 최소 변경은 전체 카탈로그를 변환하는 것이다.
다만 모든 등록 소스를 활성화한다는 정책이 된다. 소스 등록과 활성화를 분리해야 한다면 선택 목록을 별도로 유지해야 한다.
`maxDepth`를 활용하여 변환 자체를 없애려면 **각 분류 디렉터리를 별도 소스 루트로 등록**할 수 있다.

## 확인한 버전과 1차 출처

- [agent-skills-nix 고정 소스: 발견·선택·번들 구현](https://github.com/Kyure-A/agent-skills-nix/blob/5ff9039277a9d62907426d033ecf76addb2402cb/lib/default.nix)
- [고정 모듈 옵션 정의](https://github.com/Kyure-A/agent-skills-nix/blob/5ff9039277a9d62907426d033ecf76addb2402cb/modules/common.nix)
- [Matt Pocock 고정 스킬 트리](https://github.com/mattpocock/skills/tree/3cca18b368ae95cdbdebbff572ccafa662551015/skills)
- [현재 OMP 스킬 검색 문서](omp://skills.md), [설정 경로 문서](omp://config-usage.md)

## filter.maxDepth의 정확한 의미

고정 모듈의 `modules/common.nix:81-86`은 타입을 `nullOr ints.positive`, 기본값을 `null`로 정의한다.
따라서 이 버전의 모듈에서는 0이나 음수를 사용할 수 없다.

`lib/default.nix:114-163`의 탐색은 `subdir`로 정한 루트를 깊이 0으로 시작한다.
현재 디렉터리의 `SKILL.md`를 확인한 뒤 `depth < effectiveMax`일 때만 하위 디렉터리로 내려간다.
`null`은 내부적으로 최대 100이다. 발견된 ID는 루트 기준 상대 경로이며 깊이 옵션이 이 경로를 바꾸지 않는다.

```text
skills/                      깊이 0
  engineering/               깊이 1
    tdd/                     깊이 2
      SKILL.md
```

실제 고정 입력을 `discoverCatalog`에 넣어 실행한 결과:

| subdir | maxDepth | 발견 수 | ID 예시 |
|---|---:|---:|---|
| skills | 1 | 0 | 없음 |
| skills | 2 | 37 | engineering/tdd |
| skills | null | 37 | engineering/tdd |
| skills/engineering | 1 | 18 | tdd |

`maxDepth = 2`와 기본값의 카탈로그가 동일함을 확인했다.

## 대안 비교

### A. 전체 카탈로그를 일반적으로 평탄화

현재 `lib.filterAttrs (_: skill: skill.source == "mattpocock")` 부분을 없애고
`config.programs.agent-skills.catalog` 전체에 현재 변환을 적용한다.

- 장점: 최소 변경이며 특정 소스명 분기가 없다. 다른 소스의 중첩 구조도 같은 규칙으로 처리한다.
- 정책: 소스를 등록하면 그 소스의 모든 스킬을 활성화한다.
- 위험: 서로 다른 경로의 basename이 같으면 충돌한다. 현재 37개에는 충돌이 없다.
- 필수 보완: 충돌을 명시적으로 거부해야 한다. 실제 Nix 실험에서 `mapAttrs'`로 두 키를 같은 이름에 매핑하면 오류 없이 첫 값만 남았다.
- 선택적 활성화가 필요하면 별도 선택 목록으로 카탈로그를 먼저 제한한 후 변환한다.

### B. 분류별 소스 루트 + maxDepth = 1

예시 개념:

```nix
sources.mattpocock-engineering = {
  input = "mattpocock-skills";
  subdir = "skills/engineering";
  filter.maxDepth = 1;
};
skills.enableAll = true;
```

다른 분류도 같은 방식으로 등록하면 `skills.explicit` 평탄화가 필요 없다.
평탄한 ID를 만드는 것은 **subdir 변경**이고, `maxDepth = 1`은 그 루트의 직계 스킬만 검색하도록 제한하는 역할이다.

고정 소스의 `skills` 아래 실제 디렉터리를 `builtins.readDir`로 수집하고 `lib.genAttrs`로 소스를 생성하는 실험도 수행했다.
분류 `deprecated`, `engineering`, `in-progress`, `misc`, `productivity`를 등록했을 때 **37개**, 중첩 ID **0개**였다.
따라서 분류명을 직접 나열하지 않는 선언적 생성도 가능하다.

- 장점: upstream의 기본 ID 생성·중복 검사·enableAll 흐름을 그대로 사용한다. `discoverCatalog`는 소스 간 같은 ID를 명시적으로 거부한다 (`lib/default.nix:165-178`).
- 단점: 저장소가 정확히 `분류/스킬` 구조라는 가정이 생긴다. 루트 직계 스킬이나 더 깊은 스킬이 추가되면 별도 처리가 필요하다.
- 주의: `skills.enableAll = true`는 이 소스들뿐 아니라 모든 등록 소스를 활성화한다. 범위를 제한하려면 생성한 소스 이름 목록을 사용한다.
- 여러 원격 입력의 카테고리를 합칠 때는 소스 키에도 입력별 구분을 둬야 한다.

### C. OMP에 분류별 검색 디렉터리 지정

OMP는 `skills.customDirectories`도 한 단계만 탐색하지만, 각 분류 폴더를 검색 루트로 지정할 수 있다.
예를 들어 중첩 번들을 유지하고 `engineering`, `misc` 등의 폴더를 각각 등록한다.

- 장점: Nix 번들 경로를 바꾸지 않는다.
- 단점: OMP 설정과 번들 분류 구조를 함께 관리해야 한다. 다른 대상의 탐색 문제까지 해결하는 공통 변환은 아니다.
- OMP 문서에 따르면 같은 이름의 커스텀 스킬은 기본 provider보다 우선하며, 커스텀 디렉터리 간에는 먼저 발견한 항목이 우선한다. 디렉터리 이름만 바꿔도 frontmatter의 동일한 스킬 이름 충돌까지 해결되지는 않는다.

### D. enableAll 또는 rename만 변경

- `enableAll`은 선택 목록을 만들 뿐 ID를 평탄화하지 않는다 (`lib/default.nix:180-203`).
- 현재 고정 버전은 explicit의 `rename`을 계산하지만 뒤의 선택 병합·번들 생성에서 속성 키를 ID로 다시 사용한다 (`lib/default.nix:283-339`). 따라서 현재 구성에서는 평탄한 explicit 키를 만드는 방법이 필요하다.
- 실제 실험에서 원래 카탈로그를 enableAll로 선택하면서 평탄한 explicit도 추가하면 **37 + 37 = 74개**가 선택됐다. 선택 목록은 평탄화 전에 소비해야 하며, 기존 중첩 ID 선택을 동시에 활성화하면 안 된다.

## 권고

현재 구조를 유지하며 분기만 제거하려면 **A + basename 충돌 검사**가 가장 작은 변경이다.
`maxDepth` 중심의 upstream 기본 기능만 사용하고 이 저장소의 두 단계 구조를 명시적으로 받아들인다면 **B**도 유효하다.
B에서는 `maxDepth`가 평탄화 기능이라는 오해 없이, 분류별 `subdir`가 핵심이라는 점을 주석으로 남기는 것이 좋다.

## 채택 및 검증

조사 후 사용자 결정에 따라 **B: 분류별 소스 루트**를 채택했다.
`common/home/agent-skills.nix`의 `sources`에 다섯 분류를 각각 직접 선언하고,
각 소스의 `filter.maxDepth = 1`을 지정한다. 중복을 허용하여 let 바인딩,
디렉터리 자동 탐색, `mapAttrs` 없이 유지한다. 새 분류는 직접 추가해야 한다.
`skills.enableAll = true`로 등록된 모든 소스를 활성화하며 기존 `skills.explicit` 변환은 제거했다.

`make build` 성공. 빌드된 번들의 37개 스킬 이름과 `SKILL.md` 내용이 이전 번들과
동일하고, 모두 `*/SKILL.md`에 있으며 중첩 스킬 경로가 없음을 확인했다.
Fedora 구성에서도 같은 37개 스킬과 활성 소스 목록을 확인했다.
lock 파일과 시스템 활성화는 변경하지 않았다.
