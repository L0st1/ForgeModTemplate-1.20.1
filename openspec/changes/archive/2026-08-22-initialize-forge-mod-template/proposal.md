## Why

当前仓库混合了 Forge MDK、具体的 `health_control` 功能、飞机模组附属开发资料和本机环境配置，无法安全、稳定地复用于新项目。需要将其中已验证的 Forge 1.20.1 开发经验提炼为一套可参数化初始化、可重复构建、明确隔离客户端与服务端代码的通用模板。

## What Changes

- 将仓库重构为面向 Forge 1.20.1、Java 17 的单加载器 Mod 开发模板。
- 提供 PowerShell 初始化器，收集模组标识、显示名称、包名、主类、版本、作者、许可证和描述等参数，并生成可直接构建的新项目。
- 建立安全的公共端、客户端代码边界，模板不继承当前 `health_control` 的业务实现。
- 统一 Gradle、`mods.toml`、`pack.mcmeta` 和资源目录中的项目元数据，避免重复手工同步。
- 保留 `127.0.0.1:7890` 作为代理默认值，但通过可配置文件提供，并允许使用不提交的本地覆盖配置进行修改或禁用。
- 提供空白与示例初始化模式，以及 Mixin、Forge 配置、网络通信和 GameTest 等可选模块。
- 通用化本地构建、环境诊断、VS Code 任务、代码片段、中文 README、开发文档和 Codex skill。
- 清理模板不应携带的飞机 Mod JAR、旧项目功能、个人部署路径、生成产物及领域专用开发记录。
- 初始化 OpenSpec，使后续模板演进通过规格和变更记录管理。

## Capabilities

### New Capabilities

- `forge-mod-project-initialization`: 定义从模板创建 Forge 1.20.1 Mod 项目时的参数、目录生成、元数据替换、初始化模式和可选模块行为。
- `forge-mod-development-workflow`: 定义生成项目的环境诊断、代理配置、构建验证、编辑器支持、文档和本地开发工作流。

### Modified Capabilities

无。当前仓库没有已有 OpenSpec capability。

## Impact

- 将影响根目录 Gradle 配置、Wrapper、源代码与资源结构、VS Code 配置、脚本、文档、`.gitignore` 和仓库内 skill。
- 当前 `health_control` 业务代码和飞机附属 Mod 资料不再作为模板主体保留，必要的通用经验会迁移到中文模板文档。
- 模板基线固定为 Minecraft 1.20.1、Forge 47.4.0、Java 17 和 Gradle 8.8；未来其他加载器或 Minecraft 版本应作为独立变更处理。
- 初始化器以 PowerShell 为第一版入口，生成出的 Gradle 工程仍应可在 Windows 以外的平台通过 Wrapper 构建。
