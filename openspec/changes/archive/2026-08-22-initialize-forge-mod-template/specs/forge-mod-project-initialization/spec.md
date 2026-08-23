## Purpose

定义使用本仓库模板创建 Forge 1.20.1 Mod 项目时可观察、可验证的初始化行为，确保项目身份一致、端侧边界安全，并可按需组合常用开发模块。

## ADDED Requirements

### Requirement: 固定且明确的技术基线
模板生成的项目 SHALL 默认使用 Minecraft 1.20.1、Forge 47.4.0、Java 17 和 Gradle 8.8，并在项目配置与中文文档中声明该基线。

#### Scenario: 使用默认基线初始化
- **WHEN** 用户不覆盖任何技术版本参数并完成初始化
- **THEN** 生成项目的 Gradle 与 Mod 元数据声明 SHALL 与默认技术基线一致

### Requirement: 收集并验证项目身份参数
初始化器 SHALL 收集 `mod_id`、`mod_name`、`mod_group`、`java_package`、`main_class`、`mod_version`、`author`、`license` 和 `description`，并在写入项目前验证 Forge 标识、Java 包名、Java 类名和版本等参数格式。

#### Scenario: 使用有效参数初始化
- **WHEN** 用户提供全部有效的项目身份参数
- **THEN** 初始化器 SHALL 接受参数并继续生成项目

#### Scenario: 拒绝无效参数
- **WHEN** 用户提供包含大写字母的 `mod_id`、非法 Java 包名或非法主类名
- **THEN** 初始化器 SHALL 返回明确错误、非零退出码，并且不得留下部分替换的项目状态

### Requirement: 项目身份单一来源与一致传播
生成项目 SHALL 从同一组初始化参数派生 Gradle 项目名、Java 包和主类、资源命名空间、Mod 元数据及构建产物名，初始化结束后不得保留未解析占位符或旧项目身份。

#### Scenario: 验证生成项目的一致性
- **WHEN** 初始化器成功完成
- **THEN** Java 路径、`mods.toml`、`pack.mcmeta`、语言资源目录、Gradle 属性和 JAR 命名 SHALL 使用一致的项目身份

#### Scenario: 清除旧仓库身份
- **WHEN** 初始化器从当前模板创建新项目
- **THEN** 生成项目 SHALL 不包含 `health_control`、飞机加速补丁、DeceasedCraft 部署路径或旧业务类引用

### Requirement: 提供空白和示例初始化模式
初始化器 SHALL 提供空白模式与示例模式；空白模式只生成可构建的最小 Mod 入口，示例模式 SHALL 提供符合端侧隔离规则的最小可运行功能。

#### Scenario: 选择空白模式
- **WHEN** 用户选择空白模式
- **THEN** 生成项目 SHALL 能构建且不包含具体玩法功能

#### Scenario: 选择示例模式
- **WHEN** 用户选择示例模式
- **THEN** 生成项目 SHALL 包含可识别的示例功能及其资源，并能在开发客户端中加载

### Requirement: 可选择的开发模块
初始化器 SHALL 允许用户独立选择 Mixin、Forge 配置、网络通信和 GameTest 模块，仅为选中的模块生成源码、资源与构建配置。

#### Scenario: 不选择可选模块
- **WHEN** 用户接受默认的最小模块集合
- **THEN** 生成项目 SHALL 不包含未选择模块的依赖、配置或示例代码

#### Scenario: 选择多个模块
- **WHEN** 用户同时选择 Mixin、网络通信和 GameTest
- **THEN** 生成项目 SHALL 包含三个模块各自所需的配置与示例，并能够完成构建

### Requirement: 安全隔离客户端与公共端代码
模板 SHALL 保证公共 Mod 入口不直接引用客户端专属类，客户端事件和 UI 代码 SHALL 位于明确的客户端作用域；涉及权威游戏状态的示例 SHALL 在服务端处理或通过网络同步到服务端。

#### Scenario: 专用服务器加载基础项目
- **WHEN** 未声明为纯客户端的生成项目被放入 Forge 专用服务器
- **THEN** 项目 SHALL 不因加载 `net.minecraft.client` 类而启动失败

#### Scenario: 示例功能改变权威状态
- **WHEN** 示例功能需要改变由服务端控制的游戏状态
- **THEN** 客户端操作 SHALL 通过经过验证的网络消息请求服务端执行，而不是仅修改客户端静态变量

### Requirement: 初始化操作可安全重试
初始化器 SHALL 在修改前识别项目是否已经完成初始化，并拒绝无确认的重复初始化或对不兼容目录的覆盖。

#### Scenario: 对已初始化项目重复执行
- **WHEN** 用户在已经初始化的项目中再次运行初始化器且未显式确认重置
- **THEN** 初始化器 SHALL 停止并说明当前项目状态，不得覆盖现有源码或资源

