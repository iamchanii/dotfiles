# dotfiles

nix-darwin 과 Home Manager 로 관리하는 macOS 및 Fedora Asahi 설정.

## 지원 머신

- Apple Silicon macOS: `darwinConfigurations.Chanhees-MacBook-Pro`
- Fedora Asahi Remix (`aarch64-linux`): `homeConfigurations."chanhee@fedora"`

Fedora에서는 배포판의 기존 Lix를 그대로 사용하고 standalone Home Manager만
적용한다. `make switch`와 `make build`는 실행 중인 OS에 맞는 출력을 자동 선택한다.

최초 적용은 다음 두 명령으로 한다. 두 번째 명령은 `/etc/shells` 등록을 위해
sudo 암호를 요구하며 한 번만 실행하면 된다.

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
- Nushell 로그인 셸과 Starship
- Ghostty 개발판 (공식 `main` 소스 빌드, Jetendard 폰트, 불투명도 설정 없음)
- Neovim + NvChad
- npm 전역 `defuddle`
- npm/pnpm/Yarn/Bun의 최소 릴리스 경과 시간 1일 설정
- Codex용 선언적 Agent Skills
- Chromium
- 1Password 데스크톱 앱과 `op` CLI
- Fcitx 5 + Hangul (Home Manager 패키지/설정, 오른쪽 Meta 전환)
- Toshy 공식 Flake 런타임 (Fedora udev 설정과 사용자 파일 설치는 별도)
- KDE Plasma Catppuccin Mocha/Blue 테마 (Classic 창 장식과 커서 포함)

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
- **pnpm 12.4.0** — Mac/Fedora 공통 `home.packages`, 플랫폼별 공식 ARM64 네이티브 바이너리 사용 (`common/home/cli.nix`)
- **Ruby 4.0.6** — Mac 전용 `home.packages`, nixpkgs의 `mkRuby`로 최신 안정판 고정 (`common/home/cli.nix`)
- **nushell** — 기본 로그인 셸 (`programs.nushell`, `users.users.chanhee.shell`). starship 통합은 `enableNushellIntegration` 으로 자동 구성. zsh 는 복구용 안전망으로만 남겨둠 (`/etc/zshrc`)
- **Zellij** — 터미널 멀티플렉서 (`programs.zellij`). catppuccin-mocha 테마, 내부 pane 도 nushell 사용. nushell 자동 시작 통합은 없어 직접 실행할 때만 뜸
- **키보드 반복 속도 튜닝** — `KeyRepeat=2`, `InitialKeyRepeat=10`, 길게 누르기 시 액센트 메뉴 대신 반복 입력
- **Homebrew cask** — brew 로 설치하는 cask 는 모두 `darwin/system/homebrew.nix` 의 `casks` 에 선언한다 (`cleanup="zap"` 로 미선언 항목은 제거). brew 바이너리 자체는 nix 가 설치하지 않으므로 선행 설치돼 있어야 한다 (아래 설치 절차 참고). 현재 cask: `karabiner-elements`, `google-chrome`, `1password`, `obsidian`
- **Karabiner-Elements** — 키보드 커스터마이징. nix-darwin 모듈은 Karabiner v15 와 호환되지 않아 Homebrew cask 로 설치 (`darwin/system/karabiner.nix` 는 사정·수동 승인만 문서화). 키맵은 `darwin/home/karabiner.nix` 가 `karabiner.json` 을 선언적으로 생성한다:
  - **Right Command → Hyper** (⌘⌃⌥⇧)
  - **Right Option → Meh** (⌃⌥⇧, Hyper 에서 ⌘ 제외)

  `home.file` 로 만들어 `~/.config/karabiner/karabiner.json` 은 읽기 전용 심볼릭 링크다. 즉 **GUI 편집·저장은 불가**하며 키맵 변경은 `darwin/home/karabiner.nix` 의 `complex_modifications.rules` 에서 한다

## 요구사항

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
git clone <repo-url> ~/workspace/dotfiles
cd ~/workspace/dotfiles
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
| `make check` | `nix flake check` 로 flake 출력 검사 |
| `make update` | flake 입력을 최신으로 갱신 (`flake.lock` 업데이트) |

## 에이전트용 프롬프트

새 머신에서 에이전트(Claude Code 등)에게 셋업을 맡길 때 아래 프롬프트를 그대로 사용한다.

```text
이 macOS 머신에 nix-darwin dotfiles 를 설치해줘. 순서는 다음과 같아:

1. Determinate Nix 를 설치한다:
   curl -fsSL https://install.determinate.systems/nix | sh -s -- install
   설치 후 nix 가 PATH 에 잡히는지 `nix --version` 으로 확인한다.

2. dotfiles 저장소를 ~/workspace/dotfiles 에 클론하고 그 디렉터리로 이동한다.
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
