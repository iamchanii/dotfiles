# dotfiles

nix-darwin 과 Home Manager 로 관리하는 macOS 및 Fedora Asahi 설정.

## 지원 머신

- Apple Silicon macOS: `darwinConfigurations.Chanhees-MacBook-Pro`
- Fedora Asahi Remix (`aarch64-linux`): `homeConfigurations."chanhee@fedora"`

Fedora에서는 배포판의 기존 Lix를 그대로 사용하고 standalone Home Manager만
적용한다. `make switch`와 `make build`는 실행 중인 OS에 맞는 출력을 자동 선택한다.

## 저장소 구조

```text
flake.nix                      # 입력과 두 환경의 출력 연결
flake.lock                     # 기존 의존성 버전 고정
hosts/
  macbook-pro.nix               # Mac 모듈 조합, 플랫폼, UID, 상태 버전
  fedora.nix                    # Fedora 모듈 조합, 사용자 홈, 상태 버전
modules/
  shared/home/                 # 공통 CLI, Git, 셸, 에디터, 에이전트 설정
  darwin/
    system/                    # Determinate, macOS defaults, Homebrew, 폰트, 계정
    home-manager.nix           # nix-darwin과 Home Manager 통합
    home/                      # Mac 전용 Java/Android, Karabiner, Obsidian 설정
  linux/home/                  # Fedora Java/Android, KDE, 입력기, 폰트, Toshy
common/agent/AGENTS.md         # 두 환경에서 직접 참조하는 에이전트 지침 원본
common/agent/pi/settings.json  # Pi 사용자 설정 원본 (~/.pi/agent/settings.json)
common/agent/pi/extensions/    # Pi 확장 (~/.pi/agent/extensions). /adhd on|off 로 ADHD 출력 모드
common/agent/omp/config.yml    # OMP 사용자 설정 원본 (~/.omp/agent/config.yml)
common/agent/omp/extensions/adhd/ # OMP용 /adhd 확장 (~/.omp/agent/extensions/adhd)
scripts/                       # 모듈에서 사용하는 보조 스크립트
```

공통 사용자 설정은 `modules/shared/home`에서 관리하고, 각 OS의 Home Manager
진입점이 이를 가져온다. 셸 PATH와 터미널처럼 대부분을 공유하는 설정의 작은 OS
분기는 공통 모듈 안에 유지한다. Mac의 시스템 설정은 `modules/darwin/system`에만
두며, Fedora의 시스템 설정은 배포판이 계속 관리한다.

Mac에서는 `determinateNix.enable = true`가 nix-darwin의 Nix 관리를 비활성화한다.
설정이 필요하면 `determinateNix.customSettings`를 사용한다.
([공식 안내](https://docs.determinate.systems/guides/nix-darwin/))

기존 `nixpkgs` 공유 입력은 `follows`를 유지한다. Fcitx의 별도 버전 고정과
Determinate·Ghostty 등 upstream 자체의 의존성 고정은 이번 구조 변경에서 바꾸지
않는다. `system.stateVersion`과 `home.stateVersion`도 호환성 기준값이므로
패키지 업데이트에 맞춰 올리지 않는다.

Mac을 추가할 때는 `hosts/`에 머신별 파일을 추가하고 `flake.nix`에
`darwinConfigurations` 출력을 연결한다. 기존 모듈을 재사용하고 UID·플랫폼 등
실제 차이만 지정한다. 현재 패키지 구성은 두 OS 모두 ARM64를 대상으로 한다.

### 에이전트 설정

`modules/shared/home/agent.nix`는 `~/workspaces/dotfiles/common/agent`의 원본을
`mkOutOfStoreSymlink`로 연결한다. 설정과 확장을 수정하면 재빌드 없이 다음
에이전트 실행에 반영된다. 최초 링크 적용은 `make switch`로 한다.

OMP는 `~/.omp/agent/config.yml`과 `~/.omp/agent/extensions/adhd`만 관리하므로
기존의 다른 확장, 인증 정보, 세션은 유지된다. macOS에서는 기존 설정 파일을
Home Manager가 `.backup`으로 보관한 뒤 연결한다.

Pi와 OMP 모두 `/adhd`로 상태 확인, `/adhd on`과 `/adhd off`로 전환한다.
초기 상태는 켜짐이며, 각 확장 디렉터리의 `state.json`에 독립적으로 저장된다.
모드 변경은 다음 프롬프트부터 반영되고 재시작 후에도 유지된다.
OMP 버전은 기존 시스템 프롬프트 블록을 유지한 채 ADHD 규칙 블록을 추가한다.

## 셸 환경: Tern과 Ghostty

환경의 원본은 Home Manager 선언이다. `~/.config/nushell/env.nu` 같은 배포 파일이나
터미널별 PATH를 직접 수정하지 않는다.

- 변수: 해당 기능 모듈의 `home.sessionVariables`.
- 실행 경로: `home.sessionPath`. 그 외 검색 경로: `home.sessionSearchVariables`.
- npm 전역 prefix: `modules/shared/home/package-managers.nix`의
  `programs.npm.settings.prefix`. npmrc, 설치 activation, PATH가 같은 값을 사용한다.
- Bun 기본 설치 루트: 같은 파일의 `bunRoot`. Fedora는 기존 `~/.cache/.bun`,
  XDG를 사용하지 않는 Mac은 `~/.bun`을 유지한다. `BUN_INSTALL`을 명시하면 그 루트와
  `bin` 경로를 사용한다. 터미널의 `XDG_CACHE_HOME`에 따라 설치 위치를 추정하거나
  기존 패키지를 이동하지 않는다.

`shell.nix`가 생성하는 `env.nu`는 `scripts/session-env.nu`의 공통 초기화를 사용한다.
Bash 자식 프로세스에서 Home Manager의 `hm-session-vars.sh`와 기존 Nix 설치의
`nix-daemon.sh`를 평가하므로 POSIX 변수 전개를 Nushell 문법으로 복제하지 않는다.
선언된 변수와 필요한 Nix 환경만 가져오며, 부모의 초기화 완료 표시 때문에 건너뛰지 않는다.
Java/Android 변수도 이 경로로 적용된다. Fedora의 Lix 자체는 교체하지 않는다.

병합 규칙:

- 상속된 비어 있지 않은 변수는 보존하고, 없는 값/빈 값만 선언값으로 채운다.
- PATH는 **상속한 순서가 우선**이며 누락 경로만 뒤에 추가한다. 따라서 프로젝트의
  `nix develop`/가상환경 경로를 앞에서 가리지 않는다. 상속한 시스템 경로의 도구도
  추가된 사용자 경로보다 우선할 수 있다.
- PATH 중복과 빈 항목은 제거한다. 다른 검색 변수는 중복을 제거하되
  `MANPATH`의 빈 항목처럼 기본 검색 경로를 뜻하는 값은 보존한다.
- `DISPLAY`, `WAYLAND_DISPLAY` 등 런타임 환경은 터미널에서 받은 값을 유지한다.

Ghostty는 활성 Home Manager 프로필의 Nushell을 실행한다. Tern은 계정의 기본
셸을 사용한다(Fedora 최초 설정의 `make set-shell-linux`). 터미널 종류별 환경 분기는 없다.
대화형 셸과 로그인 셸에서 설정을 읽는다. 일반 `nu -c`는 `-i`를 붙여도 기본 설정을
생략하므로, 설정이 필요한 명령 실행에는 `nu --login -c '…'`를 사용하거나 스크립트에서
환경 파일을 명시적으로 `source`한다.

### 검증·적용·롤백

```sh
make check                    # Fedora와 macOS 구성 평가
make check-shell-environment  # 현재 OS 후보 세대의 env.nu 검증; 활성화하지 않음
make switch                   # 검증 후 적용
```

환경 검사는 후보 세대의 Nushell을 최소 환경으로 실행한다. 로그인/비로그인 시작,
명시적 source, 중첩 셸, 반복 초기화, 사용자 재정의, PATH 누락/빈 값,
Bun의 실제 전역 bin 경로 및 Nix 평가를 확인한다. 사용자 config.nu는 읽지 않는다.
Linux에서 macOS 구성 평가는 가능하지만 Mac 실행 검증을 대신하지는 않는다.

적용 후 **새 탭/셸**에서 확인한다. 이미 실행 중인 셸·터미널 데몬·데스크톱 세션의
환경은 소급 변경되지 않는다. Nushell은 새로 시작할 때 공통 초기화를 읽으므로 이를 위해
Tern의 기존 작업 세션을 강제 종료할 필요는 없다. 데스크톱 세션 자체의 환경 변경은
재로그인이 필요할 수 있다.

Fedora에서 되돌리려면 `home-manager generations`로 이전 세대의 저장소 경로를 확인하고,
그 경로의 `activate`를 실행한다. 이후 새 셸을 연다. Mac은 nix-darwin의 시스템 세대
롤백 절차를 따른다. 소스 변경도 별도로 되돌려야 다음 `make switch`에서 재적용되지 않는다.

## Fedora 최초 적용

최초 적용은 다음 세 명령으로 한다. GPU 설정과 로그인 셸 등록은 sudo 권한이
필요하며 최초 한 번 실행한다.

```sh
make switch
make setup-gpu-linux
make set-shell-linux
```

`setup-gpu-linux`는 Ghostty와 Chromium 같은 Nix GUI 앱이 사용할 Mesa 드라이버를
`/run/opengl-driver`에 연결한다. Fedora Asahi에서도 최초 1회 실행해야 한다.

Ghostty는 Fedora에서 `ghostty-org/ghostty`의 `main` 커밋을 `flake.lock`에 고정해
직접 빌드한다. 현재 upstream 버전 표기는 `1.3.2-dev`이며 아직 별도의 1.4 브랜치나
태그는 없다. Mac은 계속 nixpkgs의 `ghostty-bin`을 사용한다.

### Fedora 구성

- Node.js, pnpm 12.4.0, Bun, Git, GitHub CLI
- JDK 11 및 Nushell `JAVA_HOME` (Books App Android 빌드용)
- Android SDK 34, Build Tools 30.0.3, ARM64 `adb` 및 `ANDROID_HOME` (SDK 라이선스 수락)
- Nushell 로그인 셸과 Starship
- Ghostty 개발판 (공식 `main` 소스 빌드, macOS와 공통인 Jetendard 12pt, 불투명도 설정 없음)
- Neovim + NvChad
- Zellij 터미널 멀티플렉서 0.45.1 (별도 nixpkgs 리비전 고정, catppuccin-mocha 테마, pane 셸 Nushell)
- npm 전역 `defuddle`
- npm/pnpm/Yarn/Bun의 최소 릴리스 경과 시간 1일 설정
- Codex용 선언적 Agent Skills
- Chromium
- LocalSend 파일 전송 앱 (`home.packages`; 현재 Home Manager에는 `programs.localsend` 옵션이 없음)
  Fedora ARM64의 한글 네모 표시를 해결하도록 앱의 기본 본문 폰트에 정적 Pretendard
  OTF를 번들링한다 (`modules/linux/home/desktop.nix`). 시스템·터미널 폰트는 바꾸지 않는다.
- 1Password 데스크톱 앱과 `op` CLI
- Fcitx 5 + Hangul (Home Manager 패키지/설정, 오른쪽 Meta 전환)
- Toshy 공식 Flake 런타임 (Fedora udev 설정과 사용자 파일 설치는 별도)
- Flameshot 스크린샷 도구 (nixpkgs 패키지, 로그인 시 XDG autostart로 트레이 데몬 자동 시작).
  색상·저장 경로는 `flameshot config` GUI가 `~/.config/flameshot`에 직접 관리하고,
  KDE 전역 단축키(Print 등)는 시스템 설정의 사용자 지정 명령에서 `flameshot gui`에 연결한다
- KDE Plasma Catppuccin Mocha/Blue 테마 (Classic 창 장식과 커서 포함)
- KDE 세션에서 덮개 절전·유휴 절전·자동 화면 잠금 비활성화
  (전원 연결·배터리·저전력 모두). Pi 등 실행 중인 작업이 자동 절전으로 멈추지 않도록 한다.
  `make switch` 시 실행 중인 KDE에도 재로그인 없이 반영한다.
  수동 잠금·전원 버튼 동작·배터리 고갈 보호는 유지한다.
  덮개를 열어둔 상태에서도 자동 잠금이 꺼지므로 자리를 비울 때는 수동으로 잠근다

Android SDK 경로는 `make switch` 후 새 Nushell 세션에 적용된다. Google의 Linux
Build Tools와 Gradle이 받는 AAPT2는 x86_64용이므로, Fedora Asahi에서 APK를
빌드하려면 별도로 x86_64 실행 환경이 필요하다. 위 SDK 설정만으로 ARM64에서의
전체 Android 빌드가 보장되지는 않는다.

Catppuccin KDE는 공식 저장소의 생성 완료된 리소스를 `flake.lock`에 고정해 Nix
패키지로 조립한다. `make switch`를 KDE 세션에서 실행하면 Mocha/Blue 전역 테마와
Classic Aurorae 창 장식, 색상표, 스플래시 및 Mocha/Blue 커서를 함께 적용한다.

#### Fcitx 5와 Toshy

Fcitx 5 본체와 Hangul/GTK/Qt 애드온은 별도 nixpkgs 입력에 고정해 설치한다. KDE
Wayland에서는 KWin의 가상 키보드 frontend를 사용하므로 `kwinrc`에서 **Fcitx 5**가
선택돼 있어야 한다. `config`와 `profile`은 Home Manager가 관리하며 오른쪽 Meta가
보내는 `Hangul` 키로 `keyboard-us`와 `hangul`을 전환한다. Fedora의 자동 시작은
사용하지 않고 Home Manager가 설치한 KWin Wayland launcher가 Nix Fcitx를 실행한다.
Home Manager 모듈의 별도 user service는 자동 시작하지 않아 중복 실행을 막는다.

별도 Fcitx 패키지 집합의 플랫폼은 폐기 예정인 `pkgs.system` 대신
`pkgs.stdenv.hostPlatform.system`으로 지정한다.

Toshy는 upstream 공식 Flake의 실험적 Home Manager 모듈로 Python/xwaykeyz
런타임을 고정한다. udev 규칙, `uinput` 모듈 및 `input` 그룹은 NixOS 모듈 전용이라
Fedora에서는 Toshy 설치기가 만든 시스템 설정을 유지한다. 새 머신에서는 해당
설정을 준비하고 재로그인한 뒤 다음 명령으로 사용자 서비스와 KWin 파일을 설치한다.

```sh
make setup-toshy-linux
```

이 명령은 upstream `install-user-files`를 실행한 뒤 업데이트 보존 구간에
`Right Meta -> Hangul` 매핑을 멱등적으로 추가한다. 기존 설치를 업데이트할 때도
같은 명령을 사용할 수 있다.

Google Chrome은 공식 ARM64 RPM 다운로드가 아직 제공되지 않아 Fedora에서는
nixpkgs의 `aarch64-linux` Chromium을 사용한다. Mac의 Homebrew Chrome 구성은
그대로 유지한다.

## 구성 내용

- **Determinate Nix** — Nix 설치/업데이트 관리 (`determinateNix.enable`)
- **NvChad** — Neovim IDE 구성 (nix4nvchad, `programs.nvchad.enable`)
- **GitHub CLI** (`gh`) — `programs.gh.enable`
- **Node.js** — `home.packages` (`pkgs.nodejs`)
- **pnpm 12.4.0** — Mac/Fedora 공통 `home.packages`, 플랫폼별 공식 ARM64 네이티브 바이너리 사용 (`modules/shared/home/cli.nix`)
- **Ruby 4.0.6** — Mac 전용 `home.packages`, nixpkgs의 `mkRuby`로 최신 안정판 고정 (`modules/shared/home/cli.nix`)
- **JDK 26.0.2.1** — Mac 전용 Eclipse Temurin ARM64 안정판. `programs.java`와 Nushell에 `JAVA_HOME` 설정 (`modules/darwin/home/default.nix`). Fedora의 Books App용 JDK 11은 유지
- **Android SDK** — Mac 전용 Platform-Tools 37.0.0 (`adb`, `fastboot`), Command-line Tools 20.0 (`sdkmanager`, `avdmanager`), Build-Tools 37.0.0, Platform 37.0. `ANDROID_HOME`을 Nushell에도 설정. Emulator·시스템 이미지·NDK·CMake는 설치하지 않음
- **Ghostty** — Mac은 nixpkgs의 `ghostty-bin`, Fedora는 공식 `main` 소스 빌드 사용. 두 환경 모두 공통 Jetendard 12pt 사용 (`modules/shared/jetendard.nix`, `modules/shared/home/terminals.nix`)
- **Zellij 0.45.1** — 터미널 멀티플렉서 (`programs.zellij`). 0.45.1 을 담은 nixpkgs 리비전을 별도 입력(`nixpkgs-zellij`)으로 고정해 `make update` 에도 버전이 유지된다. catppuccin-mocha 테마, 내부 pane 도 nushell 사용. nushell 자동 시작 통합은 없어 직접 실행할 때만 뜸
- **키보드 반복 속도 튜닝** — `KeyRepeat=2`, `InitialKeyRepeat=10`, 길게 누르기 시 액센트 메뉴 대신 반복 입력
- **Homebrew cask** — brew 로 설치하는 cask 는 모두 `modules/darwin/system/homebrew.nix` 의 `casks` 에 선언한다 (`cleanup="zap"` 로 미선언 항목은 제거). brew 바이너리 자체는 nix 가 설치하지 않으므로 선행 설치돼 있어야 한다 (아래 설치 절차 참고). 현재 cask: `karabiner-elements`, `google-chrome`, `1password`, `obsidian`
- **Karabiner-Elements** — 키보드 커스터마이징. nix-darwin 모듈은 Karabiner v15 와 호환되지 않아 Homebrew cask 로 설치 (`modules/darwin/system/karabiner.nix` 는 사정·수동 승인만 문서화). 키맵은 `modules/darwin/home/karabiner.nix` 가 `karabiner.json` 을 선언적으로 생성한다:
  - **Right Command → Hyper** (⌘⌃⌥⇧)
  - **Right Option → Meh** (⌃⌥⇧, Hyper 에서 ⌘ 제외)

  `home.file` 로 만들어 `~/.config/karabiner/karabiner.json` 은 읽기 전용 심볼릭 링크다. 즉 **GUI 편집·저장은 불가**하며 키맵 변경은 `modules/darwin/home/karabiner.nix` 의 `complex_modifications.rules` 에서 한다

### Java와 Android SDK (macOS)

`make switch` 적용 후 새 터미널에서 확인한다:

```sh
java --version
javac --version
adb version
adb devices -l
sdkmanager --list_installed
```

실기기는 USB 디버깅을 켜고 기기에 표시되는 컴퓨터 인증을 허용해야 한다.
SDK 라이선스는 `modules/darwin/system/core.nix`에서 수락한다. SDK는 읽기 전용 Nix store에
있으므로 `sdkmanager --install` 대신 `modules/darwin/home/default.nix`의 SDK 버전 목록을
수정하고 다시 적용한다. 기존 Android 프로젝트는 해당 Gradle/AGP가 JDK 26을
지원하는지 확인하고, 지원하지 않으면 프로젝트에 맞는 JDK를 별도로 지정한다.

## macOS 요구사항

- Apple Silicon Mac (`aarch64-darwin`)
- macOS

## 설치

### 1. Determinate Nix 설치

```sh
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

설치 후 **새 셸을 열어** `nix` 가 PATH 에 잡히는지 확인한다.

```sh
nix --version
```

### 2. 저장소 클론

```sh
git clone <repo-url> ~/workspaces/dotfiles
cd ~/workspaces/dotfiles
```

### 3. Homebrew 설치

Karabiner-Elements 는 Homebrew cask 로 설치하므로 brew 바이너리가 먼저 있어야 한다.
nix-darwin 의 homebrew 모듈은 cask 만 선언적으로 관리하고 brew 자체는 설치하지 않는다.

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

> 설치 마지막에 출력되는 "Next steps" 의 PATH 설정 안내는 따라 하지 않아도 된다.
> nix-darwin 이 `make switch` 시 brew 를 알아서 호출한다.

### 4. 설정 적용

```sh
make switch
```

최초 실행 시에는 `darwin-rebuild` 가 아직 PATH 에 없는데, `make switch` 가 이 부트스트랩
상황을 자동으로 처리한다. 내부적으로 실행되는 명령은 다음과 같다.

```sh
sudo darwin-rebuild switch --flake .#Chanhees-MacBook-Pro
```

> **다른 머신에서 사용한다면** 호스트명이 다를 수 있다. `Makefile` 의 `HOST` 값과
> `flake.nix` 의 `darwinConfigurations."..."` 키를 해당 머신 이름으로 맞춰야 한다.
> 현재 호스트명은 `scutil --get LocalHostName` 으로 확인할 수 있다.

### 5. Karabiner-Elements 권한 승인

Karabiner 는 커널 수준 드라이버를 쓰기 때문에 `make switch` 후 macOS 에서 직접
승인해야 한다 (nix 가 대신 못 함).

- 시스템 설정 > 일반 > 로그인 항목 및 확장 > **드라이버 확장** 에서 활성화
- 시스템 설정 > 개인정보 보호 및 보안 > **입력 모니터링** 에서 Karabiner 허용

키 매핑 설정은 `~/.config/karabiner` 에 저장되며 GUI 로 관리한다.

## 자주 쓰는 명령

| 명령 | 설명 |
| --- | --- |
| `make switch` | 빌드 후 시스템에 적용 (최초 부트스트랩 포함) |
| `make build` | 적용하지 않고 빌드만 — 평가/빌드 오류 확인 |
| `make check` | Flake 검사와 Mac·Fedora 빌드 정의 평가 (시스템 적용 없음) |
| `make update` | flake 입력을 최신으로 갱신 (`flake.lock` 업데이트) |

## 에이전트용 프롬프트

새 머신에서 에이전트(Claude Code 등)에게 셋업을 맡길 때 아래 프롬프트를 그대로 사용한다.

```text
이 macOS 머신에 nix-darwin dotfiles 를 설치해줘. 순서는 다음과 같아:

1. Determinate Nix 를 설치한다:
   curl -fsSL https://install.determinate.systems/nix | sh -s -- install
   설치 후 nix 가 PATH 에 잡히는지 `nix --version` 으로 확인한다.

2. dotfiles 저장소를 ~/workspaces/dotfiles 에 클론하고 그 디렉터리로 이동한다.
   (이미 클론되어 있으면 이 단계는 건너뛴다.)

3. 현재 머신의 호스트명을 `scutil --get LocalHostName` 으로 확인한다.
   Makefile 의 HOST 값 및 flake.nix 의 darwinConfigurations 키와 다르면,
   두 곳을 현재 호스트명으로 맞춰 수정한다.

4. Homebrew 가 설치돼 있는지 `command -v brew` 로 확인한다. 없으면 안내만 하고
   멈춰서, 사용자가 직접 아래 명령을 실행하도록 한다 (암호 입력이 필요한
   인터랙티브 설치라 임의로 실행하지 않는다):
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

5. `make switch` 를 실행해 설정을 적용한다.

6. 적용 후, Karabiner-Elements 는 시스템 설정에서 드라이버 확장과 입력 모니터링을
   수동 승인해야 동작한다고 사용자에게 안내한다.

각 단계의 명령 출력을 그대로 보여주고, 오류가 나면 멈춰서 전체 출력을 보고해줘.
임의로 다른 도구를 설치하거나 설정을 바꾸지 마.
```
