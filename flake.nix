{
  description = "-";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    determinate.url = "github:DeterminateSystems/determinate";

    nix4nvchad = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 에이전트 스킬(SKILL.md 디렉터리)을 선언적으로 관리한다.
    agent-skills.url = "github:Kyure-A/agent-skills-nix";

    # 스킬 소스: flake 가 아니므로 flake = false 로 소스 트리만 가져온다.
    obsidian-skills = {
      url = "github:kepano/obsidian-skills";
      flake = false;
    };

    anthropics-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, determinate, ... }@inputs:
    let
      user = "chanhee";
      host = "Chanhees-MacBook-Pro";
    in {
      darwinConfigurations.${host} = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs user; };
        modules = [
          determinate.darwinModules.default
          ./darwin.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # 기존 ~/.zshrc 처럼 home-manager 가 관리하려는 파일이 이미 있으면
            # 덮어쓰기 오류 대신 .backup 으로 백업하고 진행한다.
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { inherit inputs user; };
            home-manager.users.${user} = import ./home.nix;
          }
        ];
      };
    };
}
