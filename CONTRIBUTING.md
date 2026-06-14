# 贡献指南

## 本地构建

生成 DMG：

```sh
make dmg
```

输出文件：

```text
dist/Open In Nvim.dmg
```

清理构建产物：

```sh
make clean
```

## 项目结构

核心文件：

```text
Resources/open-in-nvim.sh
Sources/OpenInNvim/main.swift
Sources/OpenInNvimFinderSync/FinderSync.swift
nvim-plugin/lua/open-in-nvim/init.lua
```

## 发布

创建并推送版本 tag：

```sh
git tag v0.3.0
git push origin v0.3.0
```

推送 `v*` tag 后，GitHub Actions 会自动构建 DMG、生成 sha256、根据上一个 tag 生成 changelog，并创建 GitHub Release。
