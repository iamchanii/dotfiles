{ ... }:
{
  # agent-skills-nix 로 에이전트 스킬을 선언적으로 관리한다.
  # 소스 input 문자열("obsidian-skills")은 extraSpecialArgs 로 전달된
  # flake inputs 를 통해 해석되므로 flake.nix 에서 inputs 가 넘어와야 한다.
  programs.agent-skills = {
    enable = true;

    sources.obsidian = {
      input = "obsidian-skills";
      subdir = "skills";
    };

    # kepano/obsidian-skills 가 제공하는 스킬 목록.
    skills.enable = [
      "defuddle"
      "json-canvas"
      "obsidian-bases"
      "obsidian-cli"
      "obsidian-markdown"
    ];

    # ~/.claude/skills 로 동기화한다.
    targets.claude.enable = true;
  };
}
