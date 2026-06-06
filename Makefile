FLAKE := .
HOST  := $(shell hostname -s)

.PHONY: switch build check update

# 설정을 빌드하고 시스템에 적용한다.
# - 먼저 nix build 로 스토어 경로를 확정한 뒤, 그 결과의 activate 스크립트를
#   직접 실행한다. 현재 활성 darwin-rebuild 에 의존하지 않아 부트스트랩 포함
#   모든 상황에서 안정적으로 동작한다.
switch:
	@OUT="$$(nix build --no-link --print-out-paths $(FLAKE)#darwinConfigurations.$(HOST).system)"; \
	echo ">> sudo $$OUT/sw/bin/darwin-rebuild activate"; \
	sudo "$$OUT/sw/bin/darwin-rebuild" activate

# 적용하지 않고 빌드만 해서 평가/빌드 오류를 확인한다.
build:
	darwin-rebuild build --flake $(FLAKE)#$(HOST)

# flake 출력 평가를 검사한다.
check:
	nix flake check

# flake 입력을 최신으로 갱신한다 (flake.lock 업데이트).
update:
	nix flake update
