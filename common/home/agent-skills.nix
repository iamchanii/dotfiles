{ ... }:
{
  # agent-skills-nix 로 에이전트 스킬을 선언적으로 관리한다.
  programs.agent-skills = {
    enable = true;

    sources = {
      mattpocock-engineering = {
        input = "mattpocock-skills";
        subdir = "skills/engineering";
        filter.maxDepth = 1;
      };

      mattpocock-productivity = {
        input = "mattpocock-skills";
        subdir = "skills/productivity";
        filter.maxDepth = 1;
      };
    };

    skills.enableAll = true;

    targets.codex.enable = true;
    targets.omp = {
      enable = true;
      dest = "$HOME/.omp/agent/skills";
    };
  };
}
