# dotfiles

MacBook Pro(macOS, Apple Silicon)의 사용자 환경을 [mise](https://mise.jdx.dev)로 관리한다.

이 저장소가 설정의 원본이다. 저장소를 `~/.dotfiles` 에 clone 하고, `$HOME` 의 설정 파일은
모두 그 checkout 을 가리키는 심링크로 둔다. 설정을 고치면 checkout 이 바로 바뀌므로
`~/.dotfiles` 에서 커밋하고 push 하면 된다.

## 저장소 구조

```text
home/                         $HOME 기준 설정 파일
  .config/mise/config.toml    도구, 패키지, macOS 기본값, 셸, 훅, task, 심링크 목록
  .config/git/config
  .config/nushell/{env.nu,config.nu}
  .config/nvim/               NvChad starter 기반 Neovim 구성
  .config/ghostty/config
  .config/pnpm/config.yaml
  .npmrc .yarnrc.yml .bunfig.toml
  .agents/AGENTS.md           에이전트 공통 지침
.gitignore                    nushell 이 만드는 mise.nu, history.txt 제외
```

배치 방식:

| 경로 | 방식 |
| --- | --- |
| `~/.config/mise` | `~/.dotfiles/home/.config/mise` 로의 디렉터리 링크 (`--config-dir`) |
| `~/.config/nvim` | `~/.dotfiles/home/.config/nvim` 로의 디렉터리 링크 |
| `~/Library/Application Support/nushell` | `~/.dotfiles/home/.config/nushell` 로의 디렉터리 링크 |
| `~/.config/git/config`, `~/.config/ghostty/config`, `~/.config/pnpm/config.yaml`, `~/.npmrc`, `~/.yarnrc.yml`, `~/.bunfig.toml` | `home/` 의 같은 경로로의 심링크 |
| `~/.agents/AGENTS.md`, `~/.codex/AGENTS.md`, `~/.claude/CLAUDE.md` | `~/.dotfiles/home/.agents/AGENTS.md` 로의 심링크 |

## `config.toml` 이 하는 일

`mise bootstrap` 은 아래를 적용한다. **로그인 셸, macOS 기본값, 시스템 패키지를 바꾼다.**

| 부분 | 내용 |
| --- | --- |
| `[tools]` | node, pnpm, gh, starship, neovim, ripgrep (모두 latest), java `temurin-26.0.2+101`, android-sdk `20.0`, ruby `3`(서드파티 tap cask 평가용) |
| `[settings]` | `minimum_release_age = "1d"` |
| `[bootstrap.packages]` | `brew:nushell`, `brew-cask:1password`, `brew-cask:spacefarm-digital/tap/sunlight`(Sunlight), `mas:869223134`(KakaoTalk) |
| `[bootstrap.macos.keyboard]` | key repeat 2, initial key repeat 15, 길게 눌러 악센트 입력 끄기 |
| `[bootstrap.user]` | 로그인 셸을 `nu` 로 변경 |
| `[bootstrap.hooks.post-tools]` | `fonts:jetendard`, `skills:restore`, Android SDK 라이선스 동의와 `platform-tools`·`build-tools;37.0.0`·`platforms;android-37.0` 설치 |
| `[tasks]` | `fonts:jetendard`(Jetendard TTF 를 `~/Library/Fonts` 에), `skills:restore` |
| `[dotfiles]` | 위 배치 방식 |

## 새 머신 설치

### 선행 조건

- mise: 공식 설치 스크립트로 설치한다.
- Homebrew: `brew:`·`brew-cask:` 패키지에 쓴다.
- Git: clone 에 쓴다.
- KakaoTalk(`mas:`)은 `mas` 가 설치되어 있고 App Store 에 로그인되어 있어야 설치된다.
  `mas` 가 없으면 bootstrap 이 이 항목만 건너뛴다(`mas not found`).

### 명령

```sh
curl https://mise.run | sh
~/.local/bin/mise bootstrap --from https://github.com/iamchanii/dotfiles.git --from-dir ~/.dotfiles --config-dir home/.config/mise --dry-run
~/.local/bin/mise bootstrap --from https://github.com/iamchanii/dotfiles.git --from-dir ~/.dotfiles --config-dir home/.config/mise
```

mise 가 저장소를 `~/.dotfiles` 에 clone 하고, `~/.config/mise` 를 checkout 의
`home/.config/mise` 로 링크한 뒤 bootstrap 을 실행한다. `~/.config/mise` 는 없거나 비어
있어야 한다.

### 기존 파일이 있으면

mise 는 기존 파일 위에 심링크를 만들지 않고 `refusing to overwrite existing files` 로
멈춘다. 지우지 말고 옮긴 뒤 다시 실행한다.

```sh
mkdir -p ~/.dotfiles-backup
mv ~/.npmrc ~/.dotfiles-backup/   # 출력에 나온 파일마다
```

`~/.config/mise` 가 이미 있으면 같은 방식으로 옮긴다.

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

## 일상 작업

설정 파일을 어디서 고쳐도 `~/.dotfiles` 의 파일이 바뀐다. `mise use -g` 도 링크를 따라
`~/.dotfiles/home/.config/mise/config.toml` 에 쓴다.

```sh
cd ~/.dotfiles
git diff
git commit -am "..."
git push
```

다른 머신에서 받기:

```sh
cd ~/.dotfiles && git pull
mise bootstrap          # 패키지·도구·링크를 다시 맞춘다
```

링크된 디렉터리(`nvim`, `nushell`) 안에 만든 파일은 바로 저장소에 생긴다. 다른 파일을
새로 관리하려면 `home/` 의 같은 경로로 옮기고 `config.toml` 의 `[dotfiles]` 에 한 줄을
추가한 뒤 `mise dot apply` 를 실행하고 커밋한다. 비밀이나 머신 전용 파일은 넣지 않는다
(공개 저장소다).

| 명령 | 설명 |
| --- | --- |
| `mise bootstrap` | 패키지, 파일, macOS 기본값, 셸, 도구, 훅 적용 |
| `mise bootstrap --dry-run` | 적용할 내용 미리보기 |
| `mise dot status` | 링크 상태 |
| `mise dot apply` | `[dotfiles]` 만 다시 적용 |
| `mise upgrade` | `[tools]` 갱신 |
| `mise bootstrap packages upgrade` | 시스템 패키지 갱신 |

이미 맞는 부분은 mise 가 다시 설치하지 않지만 `post-tools` 훅은 매번 실행된다(각 훅은
반복 실행에 안전하다).

## 에이전트 설정

에이전트 공통 지침의 원본은 `home/.agents/AGENTS.md` 하나다. `~/.agents/AGENTS.md`,
Codex(`~/.codex/AGENTS.md`), Claude Code(`~/.claude/CLAUDE.md`)는 모두 이 파일을 가리키는
심링크다.

### 스킬

user scope 스킬은 `npx skills add <source> -g` 로 설치한다. 본문은 `~/.agents/skills` 에
받아지고 설치 내역은 `~/.agents/.skill-lock.json` 에 기록된다. 이 lock 은 저장소에 없으므로
머신 간에 공유하려면 `home/.agents/.skill-lock.json` 으로 옮겨 커밋한다. `post-tools` 훅의
`mise run skills:restore` 가 lock 에는 있지만 설치되지 않은 스킬을 다시 받는다. lock 이
없으면 아무것도 하지 않는다.

### Neovim

`~/.config/nvim` 은 NvChad starter 를 시작점으로 한 구성이다. 처음 실행하면 lazy.nvim 이
`lazy-lock.json` 을 만든다. 디렉터리가 링크되어 있으므로 이 파일은 저장소에 생기고, 커밋하면
머신마다 같은 플러그인 버전을 쓴다.
NvChad 본체는 `lua/plugins` 의 lazy 스펙으로 받으므로 upstream 갱신은 `:Lazy update` 로 한다.
