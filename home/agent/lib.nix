{ lib }:
let
  toTomlValue = value:
    if builtins.isString value then builtins.toJSON value
    else if builtins.isBool value then (if value then "true" else "false")
    else if builtins.isInt value || builtins.isFloat value then toString value
    else if builtins.isList value then "[" + lib.concatMapStringsSep ", " toTomlValue value + "]"
    else throw "Unsupported TOML value: ${builtins.toJSON value}";

  renderTomlAttrs = prefix: attrs:
    let
      keyName = key: if prefix == "" then key else "${prefix}.${key}";
    in
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (key: value: "${keyName key} = ${toTomlValue value}") attrs
    );

  renderCodexMcpServer = name: server:
    let
      header = "[mcp_servers.${name}]";
      bodyAttrs = builtins.removeAttrs server [ "env" ];
      body = renderTomlAttrs "" bodyAttrs;
      env = server.env or { };
      envBody = renderTomlAttrs "" env;
    in
    lib.concatStringsSep "\n" (
      [ header ]
      ++ lib.optional (body != "") body
      ++ lib.optionals (env != { }) ([ "" "[mcp_servers.${name}.env]" ] ++ lib.optional (envBody != "") envBody)
    );
in
{
  renderCodexMcpServers = servers:
    lib.concatStringsSep "\n\n" (lib.mapAttrsToList renderCodexMcpServer servers);
}
