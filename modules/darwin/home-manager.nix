{ inputs, user, ... }:
{
  imports = [ inputs.home-manager.darwinModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # 기존 파일은 덮어쓰지 않고 .backup으로 보관한다.
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs user; };
    users.${user} = import ./home;
  };
}
