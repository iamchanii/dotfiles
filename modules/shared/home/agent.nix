{ config, ... }:
let
  # dotfiles 작업 트리의 원본을 그대로 가리킨다. ~/.codex, ~/.pi 에서 수정하면
  # 변경 내용이 이 저장소에 남는다.
  dotfiles = "${config.home.homeDirectory}/workspace/dotfiles";
in
{
  home.file = {
    # 에이전트 공통 지침. Codex와 Pi가 같은 원본을 참조한다.
    ".codex/AGENTS.md".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/common/agent/AGENTS.md";
    ".pi/agent/AGENTS.md".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/common/agent/AGENTS.md";

    # Pi 사용자 설정. ~/.pi/agent 안의 sessions, auth.json, install 등
    # 런타임 상태는 건드리지 않고 설정 파일만 연결한다.
    ".pi/agent/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/common/agent/pi/settings.json";

    # Pi 확장(/adhd 등). 확장이 기록하는 state.json 도 작업 트리에 남는다.
    ".pi/agent/extensions".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/common/agent/pi/extensions";
  };
}
