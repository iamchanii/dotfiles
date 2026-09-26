{ config, ... }:
{
  # Codex 전역 지침은 저장소의 원본 파일을 직접 가리켜 ~/.codex 에서
  # 수정해도 변경 내용이 dotfiles 작업 트리에 남도록 한다.
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/workspace/dotfiles/common/agent/AGENTS.md";
}
