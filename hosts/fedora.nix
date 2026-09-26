{ user, ... }:
{
  imports = [
    ../modules/linux/home
  ];

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = "25.11";
  };
}
