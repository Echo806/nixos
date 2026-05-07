{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        email = "2535212471@qq.com";
        name = "Echo806";
      };
    };
  };
}
