FLAKE := .
HOST  := Chanhees-MacBook-Pro

.PHONY: switch build check update

# 설정을 빌드하고 시스템에 적용한다.
# - sudo 는 자체 secure_path 만 검색하므로 PATH 의 darwin-rebuild 를
#   절대 경로로 먼저 해석한다.
# - 최초 부트스트랩(아직 switch 한 적 없어 darwin-rebuild 가 PATH 에 없음)
#   에는 빌드한 시스템 안의 darwin-rebuild 를 사용한다.
switch:
	@DR="$$(command -v darwin-rebuild)"; \
	if [ -z "$$DR" ]; then \
	  echo ">> darwin-rebuild 가 PATH 에 없음 — 빌드한 시스템에서 부트스트랩"; \
	  OUT="$$(nix build --no-link --print-out-paths $(FLAKE)#darwinConfigurations.$(HOST).system)"; \
	  DR="$$OUT/sw/bin/darwin-rebuild"; \
	fi; \
	echo ">> $$DR switch --flake $(FLAKE)#$(HOST)"; \
	sudo "$$DR" switch --flake $(FLAKE)#$(HOST)

# 적용하지 않고 빌드만 해서 평가/빌드 오류를 확인한다.
build:
	darwin-rebuild build --flake $(FLAKE)#$(HOST)

# flake 출력 평가를 검사한다.
check:
	nix flake check

# flake 입력을 최신으로 갱신한다 (flake.lock 업데이트).
update:
	nix flake update
