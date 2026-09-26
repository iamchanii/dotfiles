{ user, ... }:
{
  imports = [
    ../modules/darwin/system
    ../modules/darwin/home-manager.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  users.users.${user}.uid = 501; # 기존 계정 UID: id -u로 확인.

  # 호환성 기준값이므로 패키지 업데이트에 맞춰 올리지 않는다.
  system.stateVersion = 7;
  home-manager.users.${user}.home.stateVersion = "25.11";
}
