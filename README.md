# Forge 1.20.1 Mod 开发模板

这是一套可参数化初始化的 Minecraft Forge Mod 开发模板，固定基线为 Minecraft 1.20.1、Forge 47.4.0、Java 17 和 Gradle 8.8。模板默认生成双端安全的最小工程，可按需加入 Mixin、配置、网络通信和 GameTest。

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
- 不支持 Fabric、NeoForge、多加载器或其他 Minecraft 版本。
- 不包含 CurseForge、Modrinth 等发布流程。
