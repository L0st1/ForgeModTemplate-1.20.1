## Why

当前 Forge 模板没有统一的代码格式、静态分析或远端质量校验入口，贡献者只能依赖个人 IDE 设置，问题通常在评审或构建后才暴露。需要在不引入 Node、Python 等额外项目运行时的前提下，为 Java 17 / Gradle 8.8 模板建立可重复执行的本地与 GitHub 质量门禁。

## What Changes

- 添加基于 Spotless 与 `google-java-format` 的 Java 源码格式化和格式校验任务。
- 添加基于 Gradle 内置 PMD 的高置信静态分析任务，仅启用面向明显缺陷的规则集。
- 提供受版本控制的 Git pre-commit hook 及其安装入口，在本地提交前运行格式与静态分析校验。
- 添加 GitHub Actions 质量工作流：所有 PR 运行校验，GitHub 默认分支 `master` 的推送也运行校验。
- 更新开发文档，说明首次安装 hook、自动格式化和本地质量校验命令。

## Capabilities

### New Capabilities

- `code-quality-gates`: 为模板及其生成项目提供统一、可在本地提交和 GitHub PR/主分支上执行的格式化与静态分析质量门禁。

### Modified Capabilities

- 无。

## Impact

- 受影响文件：`build.gradle`、新增的 Git hook 与 GitHub Actions 工作流、`README.md`，以及必要的质量工具配置文件。
- 新增 Gradle 插件/工具依赖：Spotless、`google-java-format` 与 PMD；不新增应用运行时依赖。
- 初始化器逻辑和模板身份配置不变；模板生成出的项目会自然包含质量门禁文件。
- GitHub 仓库 [L0st1/ForgeModTemplate-1.20.1](https://github.com/L0st1/ForgeModTemplate-1.20.1) 的默认分支已确认是 `master`。
