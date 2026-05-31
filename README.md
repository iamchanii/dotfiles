# dotfiles

nix-darwin 과 home-manager 로 관리하는 macOS 설정.

## 구성 내용

- **Determinate Nix** — Nix 설치/업데이트 관리 (`determinateNix.enable`)
- **NvChad** — Neovim IDE 구성 (nix4nvchad, `programs.nvchad.enable`)
- **GitHub CLI** (`gh`) — `programs.gh.enable`
- **Node.js** — `home.packages` (`pkgs.nodejs`)
- **nushell** — 기본 로그인 셸 (`programs.nushell`, `users.users.chanhee.shell`). starship 통합은 `enableNushellIntegration` 으로 자동 구성. zsh 는 복구용 안전망으로만 남겨둠 (`/etc/zshrc`)
- **Zellij** — 터미널 멀티플렉서 (`programs.zellij`). catppuccin-mocha 테마, 내부 pane 도 nushell 사용. nushell 자동 시작 통합은 없어 직접 실행할 때만 뜸
- **키보드 반복 속도 튜닝** — `KeyRepeat=2`, `InitialKeyRepeat=10`, 길게 누르기 시 액센트 메뉴 대신 반복 입력
- **Homebrew cask** — brew 로 설치하는 cask 는 모두 `darwin/homebrew.nix` 의 `casks` 에 선언한다 (`cleanup="zap"` 로 미선언 항목은 제거). brew 바이너리 자체는 nix 가 설치하지 않으므로 선행 설치돼 있어야 한다 (아래 설치 절차 참고). 현재 cask: `karabiner-elements`, `google-chrome`, `1password`, `obsidian`
- **Karabiner-Elements** — 키보드 커스터마이징. nix-darwin 모듈은 Karabiner v15 와 호환되지 않아 Homebrew cask 로 설치 (`darwin/karabiner.nix` 는 사정·수동 승인만 문서화). 키맵은 `home/karabiner.nix` 가 `karabiner.json` 을 선언적으로 생성한다:
  - **Right Command → Hyper** (⌘⌃⌥⇧)
  - **Right Option → Meh** (⌃⌥⇧, Hyper 에서 ⌘ 제외)

  `home.file` 로 만들어 `~/.config/karabiner/karabiner.json` 은 읽기 전용 심볼릭 링크다. 즉 **GUI 편집·저장은 불가**하며 키맵 변경은 `home/karabiner.nix` 의 `complex_modifications.rules` 에서 한다

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
| `make check` | `nix flake check` 로 flake 출력 검사 |
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
