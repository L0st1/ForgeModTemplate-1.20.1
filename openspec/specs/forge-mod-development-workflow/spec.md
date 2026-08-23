# forge-mod-development-workflow Specification

## Purpose

定义模板生成项目的本地环境配置、诊断、构建、编辑器支持和文档体验，使开发者能够在保留个人代理默认值的同时可靠地完成跨环境开发与验证。

## Requirements

### Requirement: 可配置的代理默认值
模板 SHALL 在版本控制的专用配置中保留启用状态的 `127.0.0.1:7890` HTTP/HTTPS 代理默认值，并支持通过不提交的本地配置或显式环境设置覆盖主机、端口或禁用代理。

#### Scenario: 使用模板默认代理
- **WHEN** 用户未提供本地覆盖或显式环境设置
- **THEN** 模板构建工作流 SHALL 使用 `127.0.0.1:7890` 访问 Gradle 插件与依赖仓库

#### Scenario: 修改代理地址
- **WHEN** 用户在本地覆盖配置中指定其他主机或端口
- **THEN** 构建工作流 SHALL 使用本地覆盖值且不要求修改受版本控制的默认配置

#### Scenario: 禁用代理
- **WHEN** 用户在本地覆盖配置或环境设置中禁用代理
- **THEN** 构建工作流 SHALL 直接访问依赖仓库，并不得强制注入默认代理系统属性

#### Scenario: 保护个人代理覆盖
- **WHEN** 用户创建本地代理覆盖文件
- **THEN** Git 忽略规则 SHALL 防止该文件被默认提交

### Requirement: 环境诊断工具
模板 SHALL 提供本地诊断入口，检查 Java 17、Gradle Wrapper、关键配置、代理可用性和依赖解析条件，并为每个失败项提供可执行的中文修复建议。

#### Scenario: 环境满足要求
- **WHEN** 用户运行诊断且所有前置条件满足
- **THEN** 诊断 SHALL 返回成功状态并汇总检测到的版本与代理模式

#### Scenario: Java 版本不兼容
- **WHEN** 当前 Java 版本低于 17 或不可用
- **THEN** 诊断 SHALL 返回非零退出码并说明如何配置兼容 JDK

#### Scenario: 默认代理不可访问
- **WHEN** 代理已启用但 `127.0.0.1:7890` 不可访问
- **THEN** 诊断 SHALL 指出代理不可达，并说明修改或禁用代理配置的位置

### Requirement: 一致的本地构建入口
模板 SHALL 提供基于 Gradle Wrapper 的本地构建脚本；脚本 SHALL 在存在格式化或静态检查任务时执行这些检查，然后构建 JAR，并明确报告产物位置或失败原因。

#### Scenario: 成功构建
- **WHEN** 环境与源码有效且用户运行本地构建入口
- **THEN** 工作流 SHALL 生成以初始化后 `mod_id` 和 `mod_version` 命名的 JAR，并输出其路径

#### Scenario: 检查或构建失败
- **WHEN** 任一格式检查、编译、测试或打包任务失败
- **THEN** 构建入口 SHALL 返回非零退出码且不得报告构建成功

### Requirement: 元数据自动生成
模板 SHALL 在 Gradle 资源处理阶段从规范化项目属性生成 Mod 版本、标识、名称、作者、许可证和描述，避免要求用户在多个资源文件中手工同步相同信息。

#### Scenario: 修改项目版本
- **WHEN** 用户只修改规范化的 `mod_version` 属性并重新构建
- **THEN** 生成 JAR 的文件名和内部 Mod 元数据 SHALL 同时反映新版本

### Requirement: 编辑器与开发运行支持
模板 SHALL 提供不包含个人绝对路径的 VS Code 构建任务、常用 Forge 代码片段和开发运行配置生成说明。

#### Scenario: 在不同目录打开项目
- **WHEN** 用户将生成项目放在与模板作者不同的绝对路径并使用 VS Code
- **THEN** 构建任务 SHALL 仍通过项目内 Gradle Wrapper 工作

### Requirement: 中文开发文档
模板 SHALL 提供简体中文 README 和开发指南，说明初始化、代理覆盖、环境诊断、客户端与服务端边界、可选模块、构建、开发运行和常见故障排查。

#### Scenario: 新用户按文档完成首次构建
- **WHEN** 用户从未接触该模板并按 README 执行初始化与构建步骤
- **THEN** 文档 SHALL 提供完成首次构建所需的全部模板专属信息，不依赖旧项目开发记录

### Requirement: 通用开发助手与规格管理
模板 SHALL 包含不绑定飞机模组或具体玩法的 Forge Mod 开发 skill，并保留 OpenSpec 根目录用于管理后续需求、设计与实施任务。

#### Scenario: 使用开发 skill 处理新 Mod 功能
- **WHEN** Codex 读取生成项目中的 Forge Mod 开发 skill
- **THEN** skill SHALL 引导通用的端侧判断、事件或注册机制选择、可选 Mixin 决策、验证和本地构建，而不假设目标是飞机模组

### Requirement: 不提交生成物与个人环境文件
模板 SHALL 默认忽略构建产物、IDE 缓存、Gradle 缓存、代码图数据库、本地代理覆盖和本机部署配置。

#### Scenario: 完成构建和本地配置后检查版本控制
- **WHEN** 用户完成一次构建并创建本地覆盖配置
- **THEN** 默认待提交文件 SHALL 不包含生成 JAR、编译类、缓存、图数据库或个人代理覆盖
