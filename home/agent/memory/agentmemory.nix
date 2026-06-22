{ pkgs, ... }:

{
  systemd.user.services.agentmemory = {
    Unit = {
      Description = "agentmemory shared local memory server for coding agents";
      Documentation = "https://github.com/rohitg00/agentmemory";
      After = [ "network-online.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.nodejs}/bin/npx -y @agentmemory/agentmemory@latest";
      Restart = "on-failure";
      RestartSec = 5;
      Environment = [
        "AGENTMEMORY_HOST=127.0.0.1"
        "AGENTMEMORY_TOOLS=core"
      ];
    };

    Install.WantedBy = [ "default.target" ];
  };
}
