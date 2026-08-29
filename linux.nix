{ user, ... }:
{
  imports = [
    ./linux/home/default.nix
  ];

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = "25.11";
  };
}
