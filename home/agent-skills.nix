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

    sources.anthropics = {
      input = "anthropics-skills";
      subdir = "skills";
    };

    # obsidian 소스(kepano/obsidian-skills)는 전체 활성화한다.
    skills.enableAll = [ "obsidian" ];

    # anthropics/skills 에서 추가로 활성화할 스킬.
    skills.enable = [
      "skill-creator"
    ];

    # ~/.claude/skills 로 동기화한다.
    targets.claude.enable = true;
  };
}
