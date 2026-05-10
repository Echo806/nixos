# NixOS 环境指南

## MCP: nixos — 实时 Nix/NixOS 数据查询

你连接了一个名为 `nixos` 的 MCP 服务器，提供经过验证的 NixOS 生态数据。
**禁止凭空捏造包名、option 名、Nix 函数签名。必须先通过 MCP 查询验证。**

### 工具

| 工具 | 用途 |
|---|---|
| `nix(action="search", query="...", source="...", type="...")` | 搜索包、options、programs、flakes |
| `nix(action="info", query="...", source="...")` | 查看具体项详情 |
| `nix(action="stats", source="...")` | 统计数量/分类 |
| `nix(action="options", query="前缀", source="...")` | 按前缀浏览 options |
| `nix(action="cache", query="包名")` | 检查 binary cache 状态 |
| `nix(action="channels")` | 列出可用 NixOS 频道 |
| `nix(action="flake-inputs", type="list")` | 浏览本地 flake 依赖 |
| `nix_versions(package="包名", limit=N)` | 包版本历史（含 nixpkgs commit hash） |

### source 参数映射

| 需求 | source |
|---|---|
| 系统配置 options | `nixos` |
| Home Manager | `home-manager` |
| macOS 配置 | `darwin` |
| Neovim 插件 | `nixvim` |
| Nix 函数签名 | `noogle` |
| 文档 | `wiki` 或 `nix-dev` |
| Flake 注册表 | `flakehub` |

### type 参数映射

| 需求 | type |
|---|---|
| 软件包 | `packages` |
| 配置选项 | `options` |
| Home Manager programs | `programs` |
| Flakes | `flakes` |

### 工作流

```
# 搜索包
nix(action="search", query="firefox", source="nixos", type="packages")

# 验证 option 是否存在
nix(action="search", query="services.openssh", source="nixos", type="options")

# 查询 Nix 函数签名
nix(action="info", query="mapAttrs", source="noogle")

# 查看包版本历史
nix_versions(package="python3", limit=5)
```

### 原则

1. **可复现性优先**：一切操作以 NixOS 声明式、可复现为最高原则。修改配置 .nix 文件来达成目的，禁止随意使用 `nix-env -i`、`nix profile install`、`sudo mkdir`、`sudo ln -s` 等 imperative / 手动操作。系统状态必须由 Nix 配置文件完全描述，确保 `nixos-rebuild switch` 即可复现整个系统
2. 写 NixOS 配置前：先搜索包名/option → 确认存在 → 再写入文件
3. 不确定函数用法时：用 noogle 查签名，不要猜
4. 优先使用 `nixpkgs#` 已有包，不随意引入外部 flake
