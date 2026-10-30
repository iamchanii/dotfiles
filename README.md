# dotfiles

MacBook Pro(macOS, Apple Silicon)의 사용자 환경을 [mise](https://mise.jdx.dev)로 관리한다. 도구는 `[tools]`, 시스템 패키지와 macOS
기본값은 `[bootstrap]`, 설정 파일은 `[dotfiles]`의 `mode = "track"`이 맡는다.

## 저장소 구조

```text
home/       $HOME 기준 시드 파일 (mise history 저장소의 home/ 배치와 같다)
```

mise 구성은 `home/.config/mise/config.toml` 하나에 도구, Homebrew 패키지, 키보드
기본값, 로그인 셸, history 감시 서비스, 저장소 clone, 추적 파일 목록,
Jetendard 설치 task 를 모두 담는다.

### 추적 방식

설정 파일은 심링크가 아니라 제자리의 일반 파일이다. mise history 감시 서비스가
수정 내용을 체크포인트로 저장하고, 연결한 origin 으로 기기 간에 동기화한다.
**이 Git 저장소는 최초 시드**이고, 이후의 원본은 mise history 다. history 는 이
저장소와 섞이지 않도록 별도 비공개 저장소(또는 이 저장소의 `mise-history`
브랜치)를 origin 으로 쓴다.

`~/.config/nushell` 은 `env.nu`, `config.nu` 만 저장하고 `history.txt` 는
기기마다 둔다. macOS 에서는 `~/Library/Application Support/nushell` 을
`~/.config/nushell` 로 링크한다.

## Nix 구성에서 옮긴 것과 버린 것

| Nix 구성 | mise 대응 |
| --- | --- |
| nodejs 26, pnpm 12.4.0, gh, herdr, starship, neovim, zellij 0.45.1, opencode, uv, Ruby 4.0.6, Temurin 26.0.2.1 | `[tools]` |
| Android SDK(`androidenv`) | `android-sdk` 도구 + `post-tools` 훅의 `sdkmanager` |
| npm 전역 패키지 activation(`~/.npm-global`) | `"npm:defuddle"` |
| Homebrew cask/tap/mas, `ghostty-bin` | `[bootstrap.packages]` (opencode 는 tap 대신 `[tools]`) |
| NSGlobalDomain 키 반복 설정 | `[bootstrap.macos.keyboard]` |
| `users.users.shell = nushell` | `[bootstrap.user] login_shell` + `brew:nushell` |
| `agent.nix` 심링크 | `~/.agents/AGENTS.md` 추적 + `~/.codex/AGENTS.md`·`~/.claude/CLAUDE.md` 심링크 |
| agent-skills-nix | `npx skills add -g` + `~/.agents/.skill-lock.json`·`~/.claude/skills` 추적 + `skills:restore` task |
| git, npm/pnpm/yarn/bun 쿨다운, ghostty, zellij, nushell, karabiner | 추적 파일 |
| `home.sessionVariables`/`sessionPath` 와 `session-env.nu` | `env.nu` (Android 변수는 `android-sdk` 플러그인이 설정) |
| nix4nvchad | NvChad starter 를 시드로 한 `~/.config/nvim` 추적 (`lazy-lock.json` 포함) |
| Jetendard 소스 빌드 | 릴리스 TTF 를 받는 `fonts:jetendard` task |

버린 것: Determinate Nix, nix-darwin, Home Manager, flake 입력과 nixpkgs 고정,
Makefile, `check-shell-environment.py`, `managing-agent-skills-nix` 스킬,
Fedora Asahi 구성 전체(Fcitx 5, Toshy, KDE 테마, Flameshot, LocalSend 등).

## 이 Mac 을 Nix 에서 옮기기

1. mise 를 공식 설치 스크립트로 설치한다. Homebrew 빌드는 history 충돌 알림을
   지원하지 않는다.

   ```sh
   curl https://mise.run | sh   # ~/.local/bin/mise
   ```

2. `home/` 의 시드 파일을 `$HOME` 의 같은 경로에 일반 파일로 복사한다. Nix store 나
   이 저장소를 가리키는 기존 링크는 먼저 지운다.

3. 적용한다.

   ```sh
   mise bootstrap --dry-run
   mise bootstrap
   mise dot status
   ```

4. 새 셸에서 `nu`, `mise doctor`, `git config --get credential.https://github.com.helper` 로
   동작을 확인한 뒤 Nix 를 제거한다. nix-darwin 을 먼저 제거하고 Determinate Nix 를
   제거한다.

   ```sh
   sudo darwin-uninstaller
   sudo /nix/nix-installer uninstall
   ```

5. history origin 을 연결한다.

   ```sh
   mise dot origin set <비공개 저장소 URL> --sync sync
   ```

Karabiner-Elements 는 시스템 설정에서 드라이버 확장과 입력 모니터링을 직접
승인해야 동작한다.

## 새 머신

origin 이 연결된 뒤에는 다음 명령 하나로 추적 파일과 bootstrap 이 복원된다.

```sh
curl https://mise.run | sh
~/.local/bin/mise bootstrap --adopt <origin URL>
```

## 자주 쓰는 명령

| 명령 | 설명 |
| --- | --- |
| `mise bootstrap` | 패키지, 저장소, 파일, macOS 기본값, 셸, 도구, 훅을 모두 적용 |
| `mise dot status` | 추적·배치 파일 상태 |
| `mise dot apply` | `[dotfiles]` 만 다시 적용 |
| `mise dot sync` / `mise dot pull` | origin 과 history 를 주고받고 받은 변경을 파일에 반영 |
| `mise upgrade` | `[tools]` 갱신 |
| `mise bootstrap packages upgrade` | 시스템 패키지 갱신 |

## 에이전트 설정

에이전트 공통 지침의 원본은 `~/.agents/AGENTS.md` 하나다. mise history 가 이 파일을
추적하고, Codex(`~/.codex/AGENTS.md`)와 Claude Code(`~/.claude/CLAUDE.md`)는 이 파일을
가리키는 심링크다. 어느 경로에서 수정해도 같은 파일이 바뀌어 history 에 저장된다.

### 스킬

user scope 스킬은 `npx skills add <source> -g` 로 설치한다. 본문은
`~/.agents/skills` 에 받아지고 각 에이전트 디렉터리에는 링크가 생긴다. 설치 내역은
`~/.agents/.skill-lock.json` 에 기록된다. mise history 는 이 lock 과 `~/.claude/skills`
(직접 둔 스킬과 링크, claude.ai 가 관리하는 `synced/` 제외)만 저장한다.
`mise bootstrap` 의 `post-tools` 훅이 `mise run skills:restore` 를 실행해 lock 에는
있지만 설치되지 않은 스킬을 다시 받는다.

### Neovim

`~/.config/nvim` 은 NvChad starter 를 시작점으로 한 내 구성이다. starter 저장소의
checkout 이 아니라 일반 파일이며, mise history 가 디렉터리 전체를 추적해 다른
기기와 동기화한다. 처음 실행하면 lazy.nvim 이 `lazy-lock.json` 을 만들고, 이 파일도
함께 저장되어 기기마다 같은 플러그인 버전을 쓴다. NvChad 본체(`NvChad/NvChad`)는
`lua/plugins` 의 lazy 스펙으로 받으므로 upstream 갱신은 `:Lazy update` 로 한다.
