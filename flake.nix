{
  description = "MacBook nix-darwin and Fedora Asahi Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Fcitx는 keyboard-us 초기화가 수정된 최신 릴리스를 별도로 고정한다.
    # 나머지 시스템 패키지 갱신과 분리해 입력기 전환의 변경 범위를 제한한다.
    nixpkgs-fcitx.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Zellij 0.45.1 이 들어간 nixpkgs 리비전을 고정한다. URL 에 리비전이 박혀
    # 있어 `make update`(nix flake update) 로도 버전이 흘러가지 않는다.
    # 메인 nixpkgs 가 0.45.1 을 넘어서면 이 입력을 제거하고 pkgs.zellij 로 돌아간다.
    nixpkgs-zellij.url = "github:NixOS/nixpkgs/d54020a6ac3211e9f4201631bdf67678818c0cdf";

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

    # AI 코딩 에이전트용 터미널 워크스페이스 관리자.
    herdr = {
      url = "github:herdrdev/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Toshy의 xwaykeyz 런타임을 Nix로 고정한다. 사용자 서비스와 KWin 파일은
    # upstream install-user-files가 관리하고 Fedora의 udev 설정은 시스템에 남긴다.
    toshy = {
      url = "github:RedBearAK/Toshy/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # KDE Plasma용 Catppuccin 리소스. upstream의 생성 완료된 파일만 사용한다.
    catppuccin-kde = {
      url = "github:catppuccin/kde";
      flake = false;
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

    mattpocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };

    # JetBrains Mono Nerd Font 와 Pretendard 를 합친 한영 고정폭 폰트.
    jetendard = {
      url = "github:kuskhan/jetendard";
      flake = false;
    };
  };

  outputs = { nixpkgs, nix-darwin, home-manager, ... }@inputs:
    let
      user = "chanhee";
      host = "Chanhees-MacBook-Pro";
    in {
      darwinConfigurations.${host} = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs user; };
        modules = [ ./hosts/macbook-pro.nix ];
      };

      # Fedora Asahi에서는 시스템 설정을 건드리지 않고 기존 Lix 위에서
      # standalone Home Manager 구성만 활성화한다.
      homeConfigurations."${user}@fedora" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          localSystem.system = "aarch64-linux";
          config.allowUnfree = true;
          config.android_sdk.accept_license = true;
        };
        extraSpecialArgs = { inherit inputs user; };
        modules = [ ./hosts/fedora.nix ];
      };
    };
}
