# dotfiles

MacBook Pro(macOS, Apple Silicon)의 사용자 환경을 [mise](https://mise.jdx.dev)로 관리한다.

이 저장소가 설정의 원본이고, 저장소 루트의 `mise.toml` 이 bootstrap 프로젝트다. 모든
경로는 `mise.toml` 이 있는 디렉터리(저장소 checkout) 기준이므로 저장소를 어디에 clone 해도
된다. `$HOME` 의 설정 파일은 모두 그 checkout 을 가리키는 심링크로 두므로, 설정을 고치면
checkout 이 바로 바뀐다. checkout 에서 커밋하고 push 하면 된다.

## 저장소 구조

```text
mise.toml                     bootstrap 프로젝트: 패키지, macOS 기본값, 셸, 심링크 목록, bootstrap task
.mise/tasks/                  task 마다 실행 파일 하나 (fonts/jetendard → fonts:jetendard)
  fonts/jetendard
  skills/restore
  android/sdk
config/                       앱마다 디렉터리 하나
  mise/config.toml            전역 mise 구성: [tools], [settings]
  git/config
  ghostty/config
  nushell/{env.nu,config.nu}
  nvim/                       NvChad starter 기반 Neovim 구성
  pnpm/config.yaml
  npm/npmrc
  yarn/yarnrc.yml
  bun/bunfig.toml
agents/AGENTS.md              에이전트 공통 지침
.gitignore                    nushell 이 만드는 mise.nu, history.txt 제외
```

mise 파일이 둘인 것은 의도다. `config/mise/config.toml` 은 **전역** 구성(어느 디렉터리에서나
쓰는 도구)이고, `mise.toml` 은 이 저장소에서 실행하는 **bootstrap 프로젝트**다.
`mise.toml` 의 `[dotfiles]` 와 task 는 저장소 안에서 실행할 때만 읽힌다
(다른 곳에서는 `mise -C <checkout> ...`).

배치 방식 (`<checkout>` 은 저장소를 clone 한 디렉터리):

| 경로 | 방식 |
| --- | --- |
| `~/.config/mise/config.toml` | `<checkout>/config/mise/config.toml` 로의 심링크 |
| `~/.config/nvim` | `<checkout>/config/nvim` 로의 디렉터리 링크 |
| `~/Library/Application Support/nushell` | `<checkout>/config/nushell` 로의 디렉터리 링크 |
| `~/.config/git/config` | 로컬 파일. 끝에 `<checkout>/config/git/config` 를 include 하는 블록만 mise 가 관리한다 |
| `~/.config/ghostty/config`, `~/.config/pnpm/config.yaml` | `config/` 의 같은 앱 디렉터리로의 심링크 |
| `~/.npmrc`, `~/.yarnrc.yml`, `~/.bunfig.toml` | `config/npm/npmrc`, `config/yarn/yarnrc.yml`, `config/bun/bunfig.toml` 로의 심링크 |
| `~/.agents/AGENTS.md`, `~/.codex/AGENTS.md`, `~/.claude/CLAUDE.md` | `<checkout>/agents/AGENTS.md` 로의 심링크 |

## `mise bootstrap` 이 하는 일

저장소 안에서 `mise bootstrap` 을 실행하면 아래를 적용한다. **로그인 셸, macOS 기본값, 시스템
패키지를 바꾼다.**

| 부분 | 위치 | 내용 |
| --- | --- | --- |
| `[tools]` | `config/mise/config.toml` | node, pnpm, gh, starship, neovim, ripgrep (모두 latest), java `temurin-26.0.2+101`, android-sdk `20.0`, rust `stable`, claude `2.1.312`, ruby `3`(서드파티 tap cask 평가용) |
| `[settings]` | `config/mise/config.toml` | `minimum_release_age = "1d"` |
| `[bootstrap.packages]` | `mise.toml` | `brew:nushell`, `brew-cask:1password`, `brew-cask:spacefarm-digital/tap/sunlight`(Sunlight), `mas:869223134`(KakaoTalk) |
| `[bootstrap.macos.keyboard]` | `mise.toml` | key repeat 2, initial key repeat 15, 길게 눌러 악센트 입력 끄기 |
| `[bootstrap.user]` | `mise.toml` | 로그인 셸을 `nu` 로 변경 |
| `[vars]` | `mise.toml` | `dotfiles_root`: checkout 의 절대 경로. git include 블록 템플릿에 쓴다 |
| `[dotfiles]` | `mise.toml` | 위 배치 방식. source 는 `mise.toml` 기준 상대 경로 |
| `[tasks.bootstrap]` | `mise.toml` | bootstrap 마지막 단계에서 `fonts:jetendard`, `skills:restore`, `android:sdk` 실행 |
| task | `.mise/tasks/` | `fonts:jetendard`(Jetendard TTF 를 `~/Library/Fonts` 에), `skills:restore`, `android:sdk`(라이선스 동의, `platform-tools`·`build-tools;37.0.0`·`platforms;android-37.0`) |

## 새 머신 설치

### 선행 조건

- mise: 공식 설치 스크립트로 설치한다.
- Homebrew: `brew:`·`brew-cask:` 패키지에 쓴다.
- Git: clone 에 쓴다.
- KakaoTalk(`mas:`)은 `mas` 가 설치되어 있고 App Store 에 로그인되어 있어야 설치된다.
  `mas` 가 없으면 bootstrap 이 이 항목만 건너뛴다(`mas not found`).

### 명령

원하는 위치에 clone 하고 그 안에서 실행한다.

```sh
curl https://mise.run | sh
git clone https://github.com/iamchanii/dotfiles.git ~/workspaces/dotfiles
cd ~/workspaces/dotfiles
~/.local/bin/mise trust
~/.local/bin/mise bootstrap --dry-run
~/.local/bin/mise bootstrap
```

clone 위치는 어디든 상관없다. 심링크는 실행한 checkout 을 가리킨다. 나중에 checkout 을
옮기면 새 위치에서 `mise dot apply` 를 다시 실행한다.

### 기존 파일이 있으면

mise 는 기존 파일 위에 심링크를 만들지 않고 `refusing to overwrite existing files` 로
멈춘다. 지우지 말고 옮긴 뒤 다시 실행한다.

```sh
mkdir -p ~/.dotfiles-backup
mv ~/.npmrc ~/.dotfiles-backup/   # 출력에 나온 파일마다
```

이전 구성처럼 `~/.config/mise` 자체가 심링크라면 먼저 그 링크를 지운다(`rm ~/.config/mise`,
디렉터리 안의 파일은 저장소에 있다).

### 설치 후 확인

새 터미널을 연다(로그인 셸이 `nu` 로 바뀐다).

```sh
mise doctor
mise dot status
mise bootstrap status
```

### macOS 에서 직접 승인할 것

- 로그인 셸 변경과 일부 cask 설치 때 비밀번호를 물을 수 있다.
- 1Password, KakaoTalk 은 처음 실행할 때 로그인한다.
- 키보드 기본값은 로그아웃 후 다시 로그인해야 모든 앱에 적용된다.

### Git 설정

`git config --global` 은 심링크를 따라 원본에 쓰므로, `~/.config/git/config` 는 링크하지 않고
로컬 파일로 둔다. mise 는 그 안의 `# >>> mise:dotfiles >>>` 블록만 관리하고, 블록은 저장소의
`config/git/config` 를 include 한다.

- 모든 머신에 공통인 설정은 `config/git/config` 를 고치고 커밋한다.
- `git config --global ...` 로 쓴 값은 로컬 파일의 블록 아래에 붙어 저장소를 건드리지 않고,
  나중에 읽히므로 저장소 값보다 우선한다.
- 블록 안은 직접 고치지 않는다. checkout 을 옮기면 `mise dot apply` 가 경로를 다시 쓴다.

이전 구성에서 `~/.config/git/config` 가 심링크라면 mise 가 블록 편집을 거부한다
(`target is a symlink`). 링크를 지운 뒤(`rm ~/.config/git/config`) 다시 적용한다.

## 일상 작업

설정 파일을 어디서 고쳐도 checkout 의 파일이 바뀐다. `mise use -g` 도 링크를 따라
`config/mise/config.toml` 에 쓴다. 아래 명령은 모두 checkout 안에서 실행한다.

```sh
git diff
git commit -am "..."
git push
```

다른 머신에서 받기:

```sh
git pull
mise bootstrap          # 패키지·도구·링크를 다시 맞춘다
```

링크된 디렉터리(`nvim`, `nushell`) 안에 만든 파일은 바로 저장소에 생긴다. 다른 파일을
새로 관리하려면 `config/<앱>/` 으로 옮기고 `mise.toml` 의 `[dotfiles]` 에 상대 경로
source 로 한 줄을 추가한 뒤 `mise dot apply` 를 실행하고 커밋한다. 비밀이나 머신 전용 파일은 넣지 않는다
(공개 저장소다).

| 명령 | 설명 |
| --- | --- |
| `mise bootstrap` | 패키지, 파일, macOS 기본값, 셸, 도구, bootstrap task 적용 |
| `mise bootstrap --dry-run` | 적용할 내용 미리보기 |
| `mise dot status` | 링크 상태 |
| `mise dot apply` | `[dotfiles]` 만 다시 적용 |
| `mise upgrade` | `[tools]` 갱신 |
| `mise bootstrap packages upgrade` | 시스템 패키지 갱신 |

이미 맞는 부분은 mise 가 다시 설치하지 않지만 `bootstrap` task 는 매번 실행된다(각 task 는
반복 실행에 안전하다). task 하나만 실행하려면 `mise run fonts:jetendard` 처럼 한다.

### task 추가

`.mise/tasks/<그룹>/<이름>` 에 실행 파일을 만들고(`chmod +x`), bootstrap 때 실행할 것이면
`mise.toml` 의 `[tasks.bootstrap]` `depends` 에 `"<그룹>:<이름>"` 을 추가한다. 저장소 경로가
필요하면 `$MISE_PROJECT_ROOT` 를 쓴다.

```bash
#!/usr/bin/env bash
#MISE description="..."
set -euo pipefail
```

## 에이전트 설정

에이전트 공통 지침의 원본은 `agents/AGENTS.md` 하나다. `~/.agents/AGENTS.md`,
Codex(`~/.codex/AGENTS.md`), Claude Code(`~/.claude/CLAUDE.md`)는 모두 이 파일을 가리키는
심링크다.

### 스킬

user scope 스킬은 `npx skills add <source> -g` 로 설치한다. 본문은 `~/.agents/skills` 에
받아지고 설치 내역은 `~/.agents/.skill-lock.json` 에 기록된다. 이 lock 은 저장소에 없으므로
머신 간에 공유하려면 `agents/.skill-lock.json` 으로 옮겨 커밋하고 `[dotfiles]` 에 링크를
추가한다. `bootstrap` task 의 `skills:restore` 가 lock 에는 있지만 설치되지 않은 스킬을 다시 받는다. lock 이
없으면 아무것도 하지 않는다.

### Neovim

`~/.config/nvim` 은 NvChad starter 를 시작점으로 한 구성이다. 처음 실행하면 lazy.nvim 이
`lazy-lock.json` 을 만든다. 디렉터리가 링크되어 있으므로 이 파일은 저장소에 생기고, 커밋하면
머신마다 같은 플러그인 버전을 쓴다.
NvChad 본체는 `lua/plugins` 의 lazy 스펙으로 받으므로 upstream 갱신은 `:Lazy update` 로 한다.
