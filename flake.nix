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
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, determinate, ... }@inputs: {
    darwinConfigurations."Chanhees-MacBook-Pro" = nix-darwin.lib.darwinSystem {
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
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.chanhee = import ./home.nix;
        }
      ];
    };
  };
}
