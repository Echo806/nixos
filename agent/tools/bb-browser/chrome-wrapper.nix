{ pkgs }:

# Chrome wrapper for bb-browser with remote debugging and proxy support
pkgs.writeShellApplication {
  name = "google-chrome-remote";
  runtimeInputs = [ pkgs.google-chrome ];
  text = ''
    exec google-chrome \
      --remote-debugging-port=9222 \
      --proxy-server="http://127.0.0.1:7897" \
      "$@"
  '';
}
