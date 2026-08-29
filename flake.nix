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

    # Fedora에서는 공식 저장소 main을 고정해 차기 Ghostty 개발판을 직접 빌드한다.
    ghostty.url = "github:ghostty-org/ghostty";

    # Toshy의 xwaykeyz 런타임을 Nix로 고정한다. 사용자 서비스와 KWin 파일은
    # upstream install-user-files가 관리하고 Fedora의 udev 설정은 시스템에 남긴다.
    toshy = {
      url = "github:RedBearAK/Toshy/main";
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

    # JetBrains Mono Nerd Font 와 Pretendard 를 합친 한영 고정폭 폰트.
    jetendard = {
      url = "github:kuskhan/jetendard";
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

      # Fedora Asahi에서는 시스템 설정을 건드리지 않고 기존 Lix 위에서
      # standalone Home Manager 구성만 활성화한다.
      homeConfigurations."${user}@fedora" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-linux";
          config.allowUnfree = true;
        };
        extraSpecialArgs = { inherit inputs user; };
        modules = [ ./linux.nix ];
      };
    };
}
