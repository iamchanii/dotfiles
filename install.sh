#!/bin/sh
# 공개 시드(home/)를 $HOME 의 같은 경로에 일반 파일로 놓고 mise bootstrap 을 실행한다.
# 패키지, 도구, 서비스 등은 모두 home/.config/mise/config.toml 이 맡는다.
set -eu

usage() {
  cat <<'EOF'
사용법: install.sh [--dry-run] [--force]

  --dry-run  아무것도 쓰지 않고 시드 배치 계획과 mise bootstrap --dry-run 결과를 보여준다
  --force    내용이 다른 기존 파일·심링크를 ~/.dotfiles-backup/<시각>/ 으로 옮긴 뒤 시드를 놓는다
EOF
}

dry_run=0
force=0
for arg in "$@"; do
  case $arg in
    -n | --dry-run) dry_run=1 ;;
    --force) force=1 ;;
    -h | --help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

mise=$(command -v mise || true)
[ -n "$mise" ] || [ ! -x "$HOME/.local/bin/mise" ] || mise=$HOME/.local/bin/mise
if [ -z "$mise" ]; then
  echo "mise 가 없다. 먼저 설치한다: curl https://mise.run | sh" >&2
  exit 1
fi

# 이전에 `mise bootstrap --adopt iamchanii/dotfiles` 를 실행하면 이 저장소 전체가
# ~/.config/mise 에 clone 된다. 그 위에 시드를 놓지 않는다.
if [ -e "$HOME/.config/mise/.git" ] || [ -L "$HOME/.config/mise" ]; then
  cat >&2 <<EOF
~/.config/mise 가 Git checkout 이거나 심링크다. 시드를 놓지 않고 중단한다.
잘못된 --adopt 실행의 결과라면 README 의 "잘못된 --adopt 에서 복구" 절차를 따른다.
EOF
  exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

script_dir=$(cd "$(dirname "$0")" && pwd)
if [ -d "$script_dir/home/.config/mise" ]; then
  seed=$script_dir/home
else
  curl -fsSL https://github.com/iamchanii/dotfiles/archive/refs/heads/main.tar.gz |
    tar -xz -C "$tmp" --strip-components=1
  seed=$tmp/home
fi

(cd "$seed" && find . -type f | sed 's|^\./||' | sort) | while IFS= read -r rel; do
  dst=$HOME/$rel
  if [ -L "$dst" ]; then
    echo "conflict $rel (심링크)"
  elif [ ! -e "$dst" ]; then
    echo "copy $rel"
  elif [ -f "$dst" ] && cmp -s "$seed/$rel" "$dst"; then
    echo "same $rel"
  else
    echo "conflict $rel (내용이 다름)"
  fi
done >"$tmp/plan"

copies=$(grep -c '^copy ' "$tmp/plan" || true)
conflicts=$(grep -c '^conflict ' "$tmp/plan" || true)
echo "시드: 새로 놓음 $copies, 충돌 $conflicts, 이미 같음 $(grep -c '^same ' "$tmp/plan" || true)"
grep -v '^same ' "$tmp/plan" | sed 's/^/  /' || true

cd "$HOME"

if [ "$dry_run" = 1 ]; then
  if [ "$copies" = 0 ] && [ "$conflicts" = 0 ]; then
    exec "$mise" bootstrap --dry-run
  fi
  # 시드가 아직 없으면 dotfiles 단계의 심링크 원본이 없으므로 그 단계는 빼고 미리 본다.
  echo "mise bootstrap 미리보기 (시드 config 기준, dotfiles 단계 제외):"
  MISE_CONFIG_DIR=$seed/.config/mise exec "$mise" bootstrap --dry-run --skip dotfiles
fi

if [ "$conflicts" != 0 ] && [ "$force" = 0 ]; then
  cat >&2 <<'EOF'
기존 파일과 충돌해 아무것도 바꾸지 않고 중단한다.
이미 설치한 머신이라면 install.sh 대신 `mise bootstrap` 을 실행한다.
시드로 바꾸려면 --force 를 붙인다. 기존 것은 ~/.dotfiles-backup/<시각>/ 으로 옮겨진다.
EOF
  exit 1
fi

backup=$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)
grep -v '^same ' "$tmp/plan" | while IFS= read -r line; do
  rel=${line#* }
  rel=${rel% (*}
  if [ "${line%% *}" = conflict ]; then
    mkdir -p "$(dirname "$backup/$rel")"
    mv "$HOME/$rel" "$backup/$rel"
  fi
  mkdir -p "$(dirname "$HOME/$rel")"
  cp "$seed/$rel" "$HOME/$rel"
done

if [ -d "$backup" ]; then
  echo "기존 파일을 $backup 에 옮겼다. 되돌리기: cp -Rp '$backup/.' ~/"
fi

exec "$mise" bootstrap
