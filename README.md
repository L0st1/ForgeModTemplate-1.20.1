# Forge Mod 多版本开发模板

这是一套可参数化初始化的 Minecraft Forge Mod 开发模板，当前基线为 Minecraft 1.20.1、Forge 47.4.0、Java 17 和 Gradle 8.8。模板默认生成双端安全的最小工程，可按需加入 Mixin、配置、网络通信和 GameTest。

模板采用“一个 Minecraft 版本一个 Git 分支”的维护方式。同一个 Mod 的不同 Minecraft 大版本通常需要分别编译，不能仅通过 `mods.toml` 的版本范围共用一个 JAR。

## 作为 GitHub Template 使用

在 GitHub 仓库的 `Settings > General` 中启用 `Template repository`。用户点击 `Use this template` 创建新仓库后，在新仓库中运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\init-template.ps1
```

初始化器会替换 Mod 身份信息并移除模板蓝图。模板仓库本身不要运行初始化器；每次使用模板都应通过 GitHub 创建新的仓库。

## 创建 Minecraft 版本分支

当前仓库的 `main` 分支基于 Minecraft 1.20.1。准备适配新版本时，在干净工作区运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\create-version-branch.ps1 `
  -Version 1.21.1 `
  -ForgeVersion 52.0.0 `
  -ForgeLoaderRange '[52,)' `
  -MinecraftRange '[1.21.1,1.22)' `
  -JavaVersion 21
```

脚本会创建 `mc-1.21.1` 分支并更新构建配置。Forge 版本、加载器范围和 Java 版本必须以目标版本对应的 Forge MDK 为准；创建分支后仍需根据 Forge API 变化调整源码。

每个版本分支都应单独构建，并在 GitHub Releases 发布带版本后缀的 JAR，例如 `my_mod-0.1.0-mc1.21.1.jar`。

## 快速开始

复制本仓库后，在 PowerShell 中运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\init-template.ps1
```

初始化器会询问 Mod ID、显示名称、包名、主类、版本、作者、许可证、描述、初始化模式和可选模块。自动化场景可以使用非交互参数：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\init-template.ps1 `
  -NonInteractive `
  -ModId "my_mod" `
  -ModName "My Mod" `
  -ModGroup "com.example" `
  -JavaPackage "com.example.mymod" `
  -MainClass "MyMod" `
  -ModVersion "0.1.0" `
  -Author "Your Name" `
  -License "MIT" `
  -Description "My first Forge mod." `
  -Mode "example" `
  -Modules "config,network,gametest"
```

初始化成功后，模板蓝图会被移除并写入 `.mcmod-template-state.json`。为了保护已有源码，同一副本不能重复初始化；创建另一个项目时请重新复制模板。

## 环境诊断与构建

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\build-local.ps1
```

构建产物位于 `build/libs/<mod_id>-<mod_version>.jar`。也可以直接使用跨平台 Wrapper：

```powershell
.\gradlew.bat build
```

```bash
./gradlew build
```

## 代码质量与提交前检查

模板使用 Gradle 管理 Java 格式化和静态分析，不需要为项目安装 Node 或 Python。首次运行会下载质量工具，因此耗时通常会比后续运行长。

自动修复 Java 格式：

```powershell
.\gradlew.bat spotlessApply
```

```bash
./gradlew spotlessApply
```

运行与 CI 相同的格式和静态分析校验：

```powershell
.\gradlew.bat -b quality.gradle qualityCheck
```

```bash
./gradlew -b quality.gradle qualityCheck
```

首次克隆仓库后，安装受版本控制的 pre-commit hook：

```powershell
.\gradlew.bat installGitHooks
```

```bash
./gradlew installGitHooks
```

安装后，每次 `git commit` 都会运行基于 `quality.gradle` 的 `qualityCheck`；校验失败会取消提交，但不会自动修改暂存区。格式问题可运行 `./gradlew -b quality.gradle spotlessApply` 修复。若需要卸载本模板安装的 hook 路径，可执行 `git config --unset --local core.hooksPath`。

GitHub Actions 会在所有 PR 创建、重新打开和更新时，以及向默认分支 `master` 推送时运行同一校验。建议在 GitHub 分支保护中将 `Format and static analysis` 设为 `master` 的必需检查。

## 代理配置

模板默认启用 `127.0.0.1:7890` HTTP/HTTPS 代理，配置位于 `config/network.properties`。不应为了个人环境修改该默认文件；请新建不会被 Git 提交的 `config/network.local.properties`：

```properties
proxy.enabled=false
```

或覆盖地址：

```properties
proxy.enabled=true
proxy.host=127.0.0.1
proxy.port=10809
```

自动化环境还可以使用 `MC_MOD_PROXY_ENABLED`、`MC_MOD_PROXY_HOST` 和 `MC_MOD_PROXY_PORT`。显式系统属性或环境设置优先于本地覆盖，本地覆盖优先于模板默认值。

## 初始化模式与模块

- `blank`：默认模式，只保留可构建的公共 Mod 入口。
- `example`：增加一个客户端本地消息示例，不修改服务端权威状态。
- `mixin`：增加 Mixin 编译配置、配置文件和最小注入示例。
- `config`：增加 Forge common 配置和主类注册。
- `network`：增加方向固定的 C2S 消息、服务端处理和客户端按键示例。
- `gametest`：增加 GameTest holder 和最小测试。

可选模块只在初始化时写入；未选择的模块不会留在生成项目中。

## 目录说明

```text
config/                       代理默认配置与本地覆盖
scripts/                      初始化、环境诊断和统一构建脚本
src/main/java/                公共端与可选客户端/服务端代码
src/main/resources/           mods.toml、资源包与语言资源
template/                     初始化前的模式与模块蓝图
tests/                        初始化器脚本测试
skills/forge-mod-development/ Codex Forge 开发工作流
openspec/                     规格与变更记录
```

更详细的端侧边界、开发运行、模块机制和排错说明见 [开发指南](docs/开发指南.md)。

## 当前限制

- 初始化器第一版面向 Windows PowerShell。
- 生成项目可通过 `gradlew`/`gradlew.bat` 在其他平台构建。
- 当前基线只保证 Minecraft 1.20.1 + Forge 47.4.0；其他版本需要建立对应分支并完成源码适配。
- 不支持 Fabric、NeoForge 或多加载器共用源码。
- 不包含 CurseForge、Modrinth 等发布流程。
