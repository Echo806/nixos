{ config, pkgs, ... }:

{
  programs.noctalia-shell = {
    enable = true;
    settings = {
      bar = {
        density = "comfortable";
        position = "left";
        widgets = {
          left = [
            { id = "Launcher"; }
            { 
              formatVertical="ddd  - MMM dd - HH mm";
              id = "Clock";

            }
          ];
          center = [
            { id = "Workspace"; labelMode = "none"; hideUnoccupied = false; }
          ];
          right = [
            { id = "Tray"; }
            { id = "Battery"; warningThreshold = 30; alwaysShowPercentage = false; }
            { id = "Volume"; }
            { 
              id = "ControlCenter";
              useDistroLogo=true;
            }
          ];
        };
      };
      general=
      {
        avatarImage = "/home/run/.face/cirno.jpg";
      };
      location=
      {
        monthBeforeDay=true;
        name="Guangzhou,China";
      };
    };
    
    plugins = {
      sources = [
        {
          enabled = true;
          name = "Official Noctalia Plugins";
          url = "https://github.com/noctalia-dev/noctalia-plugins";
        }
      ];
      states = {
        catwalk = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
      };
      version = 2;
    };
    # this may also be a string or a path to a JSON file.

    pluginSettings = {
      catwalk = {
        minimumThreshold = 25;
        hideBackground = true;
      };
      # this may also be a string or a path to a JSON file.
    };
  };
}
