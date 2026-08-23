# 模板迁移清单

本清单记录将当前 Forge 项目改造成通用模板时各类内容的处理方式。迁移备份位于被 Git 忽略的 `.migration-backup/original-20260822/`。

## 仓库关联

- 本地仓库路径：`E:\Games\MC\mod`（已于 2026-08-22 查询确认）。
- 线上仓库：当前目录未检测到 `.git` 元数据，因此无法确认 Git remote，未推测链接。
- 本文档是模板迁移记录；初始化新 Mod 项目时会自动删除，不会将模板作者的绝对路径带入生成项目。

## 保留

- `gradlew`、`gradlew.bat`、`gradle/wrapper/`：保留 Gradle 8.8 Wrapper。
- `LICENSE.txt`、`CREDITS.txt`、`.gitattributes`：保留许可证与基础仓库属性。
- `openspec/`：保留变更提案、规格、设计和实施任务。

## 通用化

- `build.gradle`、`settings.gradle`、`gradle.properties`：改为参数化 Forge 1.20.1 基线和可配置代理。
- `.vscode/`：移除个人路径，补充诊断、构建和运行任务。
- `skills/forge-addon-mod/`：改造成通用 `skills/forge-mod-development/`。
- 飞机 Mod 开发记录中关于 Java、Gradle、代理、Mixin 和故障排查的经验：改写到中文开发指南。

## 替换

- `src/main/java/com/loihang/healthmod/`：替换为双端安全的 `com.example.examplemod` 最小入口。
- `src/main/resources/`：替换为从 Gradle 属性生成元数据的 `example_mod` 资源。
- `README.txt`：替换为简体中文 `README.md`。
- `开发记录.md`：通用经验迁移后由结构化文档取代。

## 移除

- `libs/immersive_aircraft-*.jar`、`libs/simpleplanes-*.jar`：第三方飞机 Mod 二进制依赖。
- `health_control`、`plane-speed-patch`、SimplePlanes、Immersive Aircraft 和 DeceasedCraft 专用实现或路径。
- `build/`、`bin/`、`.gradle/`、`.code-review-graph/`：本地生成物与索引数据库。
- Forge MDK 自带、与模板使用无关的默认英文说明和 changelog。

## 模板不得包含的标识

- 旧 Mod 标识：`health_control`、`plane-speed-patch`、`plane_speed_patch`。
- 第三方飞机 Mod 名称及其包路径。
- `DeceasedCraft_Beta` 游戏实例路径。
- `C:\Program Files\Java\latest\jdk-21` 等个人 JDK 绝对路径。
- 任何个人 Mods 部署目录。
