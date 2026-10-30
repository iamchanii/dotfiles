#!/bin/sh
# install.sh 를 임시 HOME 과 가짜 mise 로 확인한다. 실제 mise bootstrap 은 실행하지 않는다.
set -eu

repo=$(cd "$(dirname "$0")/.." && pwd)
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT

mkdir -p "$root/bin"
cat >"$root/bin/mise" <<'EOF'
#!/bin/sh
echo "${MISE_CONFIG_DIR:-} $*" >>"$MISE_LOG"
EOF
chmod +x "$root/bin/mise"

run() { h=$1 && shift && HOME=$h MISE_LOG=$h.log PATH="$root/bin:/usr/bin:/bin" sh "$repo/install.sh" "$@"; }
fail() { echo "FAIL: $*" >&2; exit 1; }
seeds=$(cd "$repo/home" && find . -type f | wc -l | tr -d ' ')

# 미리보기는 아무것도 쓰지 않고 시드 config 로 bootstrap 을 미리 본다.
h=$root/dry && mkdir -p "$h"
run "$h" --dry-run >/dev/null
[ -z "$(ls -A "$h")" ] || fail "dry-run 이 HOME 에 썼다"
grep -qx "$repo/home/.config/mise bootstrap --dry-run --skip dotfiles" "$h.log" || fail "dry-run mise 호출"

# 빈 HOME: 모든 시드가 같은 상대 경로에 놓이고 bootstrap 이 실행된다.
h=$root/fresh && mkdir -p "$h"
run "$h" >/dev/null
[ "$(cd "$h" && find . -type f | wc -l | tr -d ' ')" = "$seeds" ] || fail "시드 개수"
diff -r "$repo/home" "$h" >/dev/null || fail "시드 내용"
[ ! -e "$h/.config/mise/home" ] || fail "중첩 home/"
grep -qx " bootstrap" "$h.log" || fail "bootstrap 호출"

# 두 번째 실행: 바뀌는 것 없이 bootstrap 만 다시 실행한다.
run "$h" >/dev/null
[ ! -e "$h/.dotfiles-backup" ] || fail "재실행 백업"
[ "$(grep -c bootstrap "$h.log")" = 2 ] || fail "재실행 bootstrap"

# 충돌: 다른 내용의 파일과 심링크가 있으면 아무것도 바꾸지 않고 중단한다.
echo mine >"$h/.npmrc"
rm "$h/.yarnrc.yml" && ln -s /dev/null "$h/.yarnrc.yml"
rm "$h/.bunfig.toml"
! run "$h" >/dev/null 2>&1 || fail "충돌인데 성공"
[ ! -e "$h/.bunfig.toml" ] || fail "충돌인데 배치"
[ "$(grep -c bootstrap "$h.log")" = 2 ] || fail "충돌인데 bootstrap"

# --force: 기존 것을 백업으로 옮기고 시드를 놓는다. 백업에서 되돌릴 수 있다.
run "$h" --force >/dev/null
diff -r "$repo/home" "$h" -x .dotfiles-backup >/dev/null || fail "force 후 내용"
b=$(echo "$h"/.dotfiles-backup/*)
[ "$(cat "$b/.npmrc")" = mine ] && [ -L "$b/.yarnrc.yml" ] || fail "백업 내용"
cp -Rp "$b/." "$h/"
[ "$(cat "$h/.npmrc")" = mine ] || fail "백업 복구"

# 잘못된 --adopt 로 생긴 ~/.config/mise checkout 위에는 --force 여도 놓지 않는다.
h=$root/adopted && mkdir -p "$h/.config/mise/.git"
! run "$h" --force >/dev/null 2>&1 || fail "checkout 위에 배치"
[ "$(ls -A "$h")" = .config ] || fail "checkout 인데 배치"

echo ok
