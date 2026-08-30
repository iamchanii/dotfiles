# path: 참조는 Git 미추적 파일도 포함하므로 새 머신 부트스트랩과 개발 중 평가가
# 동일하게 동작한다.
FLAKE := path:.
HOST  := $(shell hostname -s)
UNAME := $(shell uname -s)

.PHONY: switch switch-darwin switch-linux set-shell-linux setup-gpu-linux setup-toshy-linux build build-darwin build-linux check update

# 설정을 빌드하고 시스템에 적용한다.
# - 먼저 nix build 로 스토어 경로를 확정한 뒤, 그 결과의 activate 스크립트를
#   직접 실행한다. 현재 활성 darwin-rebuild 에 의존하지 않아 부트스트랩 포함
#   모든 상황에서 안정적으로 동작한다.
ifeq ($(UNAME),Darwin)
switch: switch-darwin
build: build-darwin
else
switch: switch-linux
build: build-linux
endif

switch-darwin:
	@set -eu; \
	OUT="$$(nix build --no-link --print-out-paths $(FLAKE)#darwinConfigurations.$(HOST).system)"; \
	echo ">> sudo $$OUT/sw/bin/darwin-rebuild activate"; \
	sudo "$$OUT/sw/bin/darwin-rebuild" activate

# 적용하지 않고 빌드만 해서 평가/빌드 오류를 확인한다.
build-darwin:
	darwin-rebuild build --flake $(FLAKE)#$(HOST)

# Fedora Asahi standalone Home Manager 구성.
switch-linux:
	@set -eu; \
	OUT="$$(nix build --no-link --print-out-paths $(FLAKE)#homeConfigurations.chanhee@fedora.activationPackage)"; \
	"$$OUT/activate"
	@if [ "$$SHELL" != "$(HOME)/.nix-profile/bin/nu" ]; then \
		echo ">> 최초 1회 'make set-shell-linux'를 실행해 Nushell을 로그인 셸로 지정하세요."; \
	fi

# Nix store 해시 대신 세대가 바뀌어도 유지되는 profile 경로를 로그인 셸로 쓴다.
set-shell-linux:
	@test -x "$(HOME)/.nix-profile/bin/nu"
	@grep -Fxq "$(HOME)/.nix-profile/bin/nu" /etc/shells || \
		echo "$(HOME)/.nix-profile/bin/nu" | sudo tee -a /etc/shells >/dev/null
	@chsh -s "$(HOME)/.nix-profile/bin/nu"

# Nix GUI 앱(Ghostty, Chromium)이 사용할 Mesa 드라이버 링크를 설치한다.
setup-gpu-linux:
	@test -x "$(HOME)/.nix-profile/bin/non-nixos-gpu-setup"
	sudo "$(HOME)/.nix-profile/bin/non-nixos-gpu-setup"

# Nix 런타임을 이용해 Toshy 사용자 서비스/KWin 파일을 설치하고 로컬 키맵을 넣는다.
# udev 규칙과 input 그룹은 Fedora 시스템에 미리 구성돼 있어야 한다.
setup-toshy-linux: switch-linux
	@id -nG | tr ' ' '\n' | grep -Fxq input || { \
		echo ">> 현재 세션에 input 그룹이 없습니다. 재로그인 또는 재부팅 후 다시 실행하세요."; \
		exit 1; \
	}
	toshy-install-user-files
	toshy-apply-customizations

build-linux:
	nix build --no-link $(FLAKE)#homeConfigurations.chanhee@fedora.activationPackage

# flake 출력 평가를 검사한다.
check:
	nix flake check

# flake 입력을 최신으로 갱신한다 (flake.lock 업데이트).
update:
	nix flake update
