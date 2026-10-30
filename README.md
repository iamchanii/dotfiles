# dotfiles

MacBook Pro(macOS, Apple Silicon)의 사용자 환경을 [mise](https://mise.jdx.dev)로 관리한다.

이 공개 저장소는 **최초 시드**다. 새 머신에 처음 놓을 설정 파일을 담고 있을 뿐,
설치 이후의 원본은 아니다. 설치 후에는 설정 파일이 `$HOME` 의 제자리에 일반 파일로
있고, mise history(`mode = "track"`)가 그 수정 내용을 체크포인트로 저장한다. 다른
머신과의 동기화는 직접 만든 **비공개 history origin** 으로 한다.

| | 공개 시드 저장소 (이 저장소) | history origin (직접 만드는 비공개 저장소) |
| --- | --- | --- |
| 내용 | `home/` 아래 시드 파일 | mise history 체크포인트 (`.mise-history/` 메타데이터 포함) |
| 쓰는 곳 | 새 머신 최초 설치: `install.sh` | 다른 머신 복원: `mise bootstrap --adopt <history origin>` |
| 갱신 | 손으로 커밋 | 감시 서비스가 자동 저장, `mise dot sync` |

이 저장소를 `mise bootstrap --adopt iamchanii/dotfiles` 로 쓰면 안 된다. history
메타데이터가 없는 저장소는 global config 저장소로 취급되어 저장소 전체가
`~/.config/mise` 에 clone 되고, 설정은 `~/.config/mise/home/.config/mise/config.toml`
에 묻혀 읽히지 않는다. 이때 출력은 `mise all tools are installed` 뿐이다.
[복구 방법](#잘못된---adopt-에서-복구)

## 저장소 구조

```text
install.sh               최초 설치 진입점: home/ 를 $HOME 에 배치한 뒤 mise bootstrap 실행
home/                    $HOME 기준 시드 파일
  .config/mise/config.toml   도구, 패키지, macOS 기본값, 셸, 서비스, 훅, task, 추적 목록
  .config/git/config
  .config/nushell/{env.nu,config.nu}
  .config/nvim/              NvChad starter 기반 Neovim 구성
  .config/ghostty/config
  .config/pnpm/config.yaml
  .npmrc .yarnrc.yml .bunfig.toml
  .agents/AGENTS.md          에이전트 공통 지침
test/install.test.sh     install.sh 검사 (임시 HOME, 가짜 mise)
```

설정의 원본은 `home/` 하나다. `install.sh` 는 시드를 복사하고 mise 를 호출할 뿐이고,
패키지·도구·서비스는 모두 `config.toml` 이 맡는다.

## `config.toml` 이 하는 일

`mise bootstrap` 은 아래를 적용한다. **로그인 셸, macOS 기본값, 시스템 패키지,
LaunchAgent 를 바꾼다.**

| 부분 | 내용 |
| --- | --- |
| `[tools]` | node, pnpm, gh, starship, neovim, ripgrep (모두 latest), java `temurin-26.0.2+1`, android-sdk `20.0` |
| `[settings]` | `minimum_release_age = "1d"` |
| `[bootstrap.packages]` | `brew:nushell`, `brew-cask:1password`, `mas:869223134`(KakaoTalk) |
| `[bootstrap.macos.keyboard]` | key repeat 2, initial key repeat 15, 길게 눌러 악센트 입력 끄기 |
| `[bootstrap.user]` | 로그인 셸을 `nu` 로 변경 |
| `[bootstrap.services.mise-history]` | history 감시 LaunchAgent (`~/Library/LaunchAgents/dev.mise.mise-history.plist`) |
| `[bootstrap.hooks.post-tools]` | `fonts:jetendard`, `skills:restore`, Android SDK 라이선스 동의와 `platform-tools`·`build-tools;37.0.0`·`platforms;android-37.0` 설치 |
| `[tasks]` | `fonts:jetendard`(Jetendard TTF 를 `~/Library/Fonts` 에), `skills:restore` |
| `[dotfiles]` | 아래 추적 목록 |

### 추적 파일과 심링크

`mode = "track"` 은 파일을 제자리에 둔 채 history 에 저장한다. **어디서 파일을
복사해 오지 않는다.** 그래서 새 머신에서는 `install.sh` 가 시드를 먼저 놓아야 한다.

| 경로 | 방식 |
| --- | --- |
| `~/.config/mise`, `~/.config/git/config`, `~/.config/ghostty/config`, `~/.config/nvim` | track |
| `~/.config/nushell` (`env.nu`, `config.nu` 만. `history.txt` 는 머신별) | track |
| `~/.npmrc`, `~/.config/pnpm/config.yaml`, `~/.yarnrc.yml`, `~/.bunfig.toml` | track |
| `~/.agents/AGENTS.md`, `~/.agents/.skill-lock.json`, `~/.claude/skills`(`synced/` 제외) | track |
| `~/Library/Application Support/nushell` → `~/.config/nushell` | symlink |
| `~/.codex/AGENTS.md`, `~/.claude/CLAUDE.md` → `~/.agents/AGENTS.md` | symlink |

`.skill-lock.json` 과 `~/.claude/skills` 는 시드에 없다. 설치 후 스킬을 추가하면
history 에 저장된다.

## 새 머신 최초 설치 (공개 저장소)

history origin 이 없어도 된다.

### 선행 조건

- mise: 공식 설치 스크립트로 설치한다. Homebrew 빌드는 history 충돌 알림을 지원하지 않는다.
- Homebrew: `brew:`·`brew-cask:` 패키지에 쓴다.
- KakaoTalk(`mas:`)은 `mas` 가 설치되어 있고 App Store 에 로그인되어 있어야 설치된다.
  `mas` 가 없으면 bootstrap 이 이 항목만 건너뛴다(`mas not found`).
- `install.sh` 자체는 Git 이 필요 없다. `curl` 과 `tar` 로 `main` 의 tarball 을 받는다.

### 명령

zsh(macOS 기본 셸)에서 실행한다.

```sh
curl https://mise.run | sh
curl -fsSL https://raw.githubusercontent.com/iamchanii/dotfiles/main/install.sh -o /tmp/dotfiles-install.sh
sh /tmp/dotfiles-install.sh --dry-run   # 미리보기: 아무것도 쓰지 않는다
sh /tmp/dotfiles-install.sh             # 시드 배치 후 mise bootstrap
```

`install.sh` 는 `PATH` 의 mise 나 `~/.local/bin/mise` 를 쓴다. 저장소를 clone 해 두었다면
`./install.sh` 로 실행해도 된다. 그때는 받지 않고 그 checkout 의 `home/` 을 쓴다.

`install.sh` 가 하는 일:

1. `~/.config/mise` 가 Git checkout 이거나 심링크면 아무것도 하지 않고 중단한다.
2. `home/<경로>` 마다 `~/<경로>` 를 확인한다. 없으면 복사, 내용이 같으면 그대로, 다른
   파일·심링크·디렉터리가 있으면 충돌이다. 충돌이 하나라도 있으면 아무것도 바꾸지 않고
   중단한다.
3. `$HOME` 에서 `mise bootstrap` 을 실행한다. 확인 질문은 mise 가 한다.

`--dry-run` 은 배치 계획과 `mise bootstrap --dry-run` 결과를 보여준다. 시드가 아직 없으면
mise 가 시드의 `config.toml` 을 읽도록 하고(`MISE_CONFIG_DIR`), 심링크 원본이 아직 없는
dotfiles 단계는 빼고 보여준다.

### 설치 후 확인

새 터미널을 연다(로그인 셸이 `nu` 로 바뀐다).

```sh
mise doctor
mise dot status          # 추적 파일과 심링크 상태
mise bootstrap status    # 각 부분이 설정과 맞는지
```

### macOS 에서 직접 승인할 것

- 로그인 셸 변경과 일부 cask 설치 때 비밀번호를 물을 수 있다.
- 1Password, KakaoTalk 은 처음 실행할 때 로그인한다.
- 키보드 기본값은 로그아웃 후 다시 로그인해야 모든 앱에 적용된다.
- `mise-history` LaunchAgent 가 로그인 항목에 나타날 수 있다. 끄면 자동 저장이 멈춘다.

## 기존 파일이 있는 머신

`install.sh` 는 충돌하면 바꾸지 않고 중단하며 충돌 목록을 보여준다. 선택지는 둘이다.

- 기존 파일을 유지: 그 파일을 직접 정리한 뒤 다시 실행한다.
- 시드로 교체: `--force` 를 붙인다. 충돌한 파일·심링크·디렉터리를
  `~/.dotfiles-backup/<YYYYmmdd-HHMMSS>/<같은 경로>` 로 **옮긴 뒤** 시드를 놓는다.
  지우지 않는다.

```sh
sh /tmp/dotfiles-install.sh --dry-run --force   # 무엇이 백업될지 확인
sh /tmp/dotfiles-install.sh --force
```

되돌리기: 백업 디렉터리를 `$HOME` 위에 다시 복사한다.

```sh
cp -Rp ~/.dotfiles-backup/<YYYYmmdd-HHMMSS>/. ~/
```

심링크 세 개(`~/Library/Application Support/nushell`, `~/.codex/AGENTS.md`,
`~/.claude/CLAUDE.md`)는 mise 가 만든다. 그 자리에 일반 파일이 있으면 mise 가
`refusing to overwrite existing files` 로 멈춘다. 그 파일을 다른 곳으로 옮기고
`mise bootstrap` 을 다시 실행한다. nushell 을 먼저 실행해 본 머신이면
`~/Library/Application Support/nushell` 이 이미 있을 수 있다.

## 반복 실행과 업데이트

두 가지를 혼동하지 않는다.

- **설치한 머신의 설정 변경**: 파일을 제자리에서 고친다. history 가 저장하고 origin 으로
  동기화한다. 패키지·도구를 다시 맞추려면 `mise bootstrap` 을 실행한다.
  `install.sh` 를 다시 실행할 필요가 없다.
- **공개 시드 갱신**: 앞으로의 새 머신을 위해 이 저장소의 `home/` 을 손으로 고쳐 커밋한다.
  이미 설치한 머신에는 영향이 없다. `~/.config/mise/config.local.toml`(origin 연결 정보)이나
  비밀, 머신 전용 파일은 복사하지 않는다.

`install.sh` 를 다시 실행해도 안전하다. 같은 파일은 건드리지 않고 `mise bootstrap` 만 다시
실행한다. 설치 후 고친 파일이 있으면 충돌로 중단한다. 이미 맞는 부분은 mise 가 다시
설치하지 않지만 `post-tools` 훅은 매번 실행된다(각 훅은 반복 실행에 안전하다).

| 명령 | 설명 |
| --- | --- |
| `mise bootstrap` | 패키지, 서비스, 파일, macOS 기본값, 셸, 도구, 훅 적용 |
| `mise bootstrap --dry-run` | 적용할 내용 미리보기 |
| `mise dot status` | 추적·배치 파일 상태 |
| `mise dot apply` | `[dotfiles]` 만 다시 적용 |
| `mise upgrade` | `[tools]` 갱신 |
| `mise bootstrap packages upgrade` | 시스템 패키지 갱신 |

## history origin 연결 (최초 설치 후 선택)

origin 은 자동으로 만들거나 연결하지 않는다. 직접 **비공개** 저장소를 만든다. 이 공개
저장소나 그 브랜치를 origin 으로 쓰지 않는다. 지금까지 저장된 모든 체크포인트가 올라간다.

```sh
mise dot origin set <비공개 저장소 URL> --sync sync
mise dot sync
```

연결 정보는 `~/.config/mise/config.local.toml` 에 기록된다. Git 인증(SSH 키나
`gh auth login`)은 직접 준비한다.

## 기존 history origin 으로 다른 머신 복원

위에서 origin 을 연결한 적이 있을 때만 쓴다. 이 경우에는 `install.sh` 를 실행하지 않는다.

```sh
curl https://mise.run | sh
~/.local/bin/mise bootstrap --adopt <history origin URL>
```

mise 가 `.mise-history/format.toml` 로 history 저장소임을 알아보고 추적 파일을 제자리에
복원한 뒤 그 config 로 bootstrap 을 실행한다. 이미 history 가 있는 머신이면
`--replace-history`, 기존 파일을 모두 origin 쪽으로 바꾸려면 `--take-remote-all` 이 필요할
수 있다(바뀐 파일은 `mise dot undo` 로 되돌린다).

## 잘못된 `--adopt` 에서 복구

`mise bootstrap --adopt iamchanii/dotfiles` 를 실행했다면 `~/.config/mise` 에 이 저장소
checkout 이 있다. mise 는 그 밖에 따로 남긴 것이 없다. zsh 에서 실행한다.

```sh
# 1. 이 저장소의 깨끗한 checkout 인지 확인한다. 다른 URL 이거나 변경이 있으면 멈추고 직접 살핀다.
git -C ~/.config/mise remote get-url origin   # https://github.com/iamchanii/dotfiles.git
git -C ~/.config/mise status --short          # 출력이 없어야 한다

# 2. 지우지 않고 백업으로 옮긴다.
mkdir -p ~/.dotfiles-backup
mv ~/.config/mise ~/.dotfiles-backup/mise-adopt-checkout

# 3. 최초 설치를 진행한다.
curl -fsSL https://raw.githubusercontent.com/iamchanii/dotfiles/main/install.sh -o /tmp/dotfiles-install.sh
sh /tmp/dotfiles-install.sh --dry-run
sh /tmp/dotfiles-install.sh
```

설치가 끝나고 문제가 없으면 `~/.dotfiles-backup/mise-adopt-checkout` 은 지워도 된다.

## 에이전트 설정

에이전트 공통 지침의 원본은 `~/.agents/AGENTS.md` 하나다. Codex(`~/.codex/AGENTS.md`)와
Claude Code(`~/.claude/CLAUDE.md`)는 이 파일을 가리키는 심링크다. 어느 경로에서 수정해도
같은 파일이 바뀌어 history 에 저장된다.

### 스킬

user scope 스킬은 `npx skills add <source> -g` 로 설치한다. 본문은 `~/.agents/skills` 에
받아지고 각 에이전트 디렉터리에는 링크가 생긴다. 설치 내역은 `~/.agents/.skill-lock.json`
에 기록된다. history 는 이 lock 과 `~/.claude/skills`(claude.ai 가 관리하는 `synced/` 제외)만
저장한다. `post-tools` 훅의 `mise run skills:restore` 가 lock 에는 있지만 설치되지 않은
스킬을 다시 받는다. lock 이 없으면 아무것도 하지 않는다.

### Neovim

`~/.config/nvim` 은 NvChad starter 를 시작점으로 한 구성이다. starter 저장소의 checkout 이
아니라 일반 파일이며, history 가 디렉터리 전체를 추적한다. 처음 실행하면 lazy.nvim 이
`lazy-lock.json` 을 만들고, 이 파일도 함께 저장되어 머신마다 같은 플러그인 버전을 쓴다.
NvChad 본체는 `lua/plugins` 의 lazy 스펙으로 받으므로 upstream 갱신은 `:Lazy update` 로 한다.
