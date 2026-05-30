# dotfiles

nix-darwin 과 home-manager 로 관리하는 macOS 설정.

## 구성 내용

- **Determinate Nix** — Nix 설치/업데이트 관리 (`determinateNix.enable`)
- **NvChad** — Neovim IDE 구성 (nix4nvchad, `programs.nvchad.enable`)
- **GitHub CLI** (`gh`) — `programs.gh.enable`
- **Node.js** — `home.packages` (`pkgs.nodejs`)
- **zsh** — 기본 셸
- **키보드 반복 속도 튜닝** — `KeyRepeat=2`, `InitialKeyRepeat=10`, 길게 누르기 시 액센트 메뉴 대신 반복 입력

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

### 3. 설정 적용

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

4. `make switch` 를 실행해 설정을 적용한다.

각 단계의 명령 출력을 그대로 보여주고, 오류가 나면 멈춰서 전체 출력을 보고해줘.
임의로 다른 도구를 설치하거나 설정을 바꾸지 마.
```
