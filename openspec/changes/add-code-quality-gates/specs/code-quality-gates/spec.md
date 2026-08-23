## Purpose

为 Forge Mod 模板及其生成项目提供一致、低门槛且可自动验证的 Java 代码质量反馈，减少个人开发环境差异导致的格式与静态缺陷遗漏。

## ADDED Requirements

### Requirement: 本地格式化与静态分析入口

模板 SHALL 提供基于 Gradle Wrapper 的独立质量校验入口，以及可修复格式问题的格式化入口；两者均不得要求项目安装 Node、Python 或其他应用运行时。

#### Scenario: 开发者修复格式

- **WHEN** 开发者执行文档所述的格式化命令
- **THEN** 模板管理范围内的 Java 源码 SHALL 被统一为仓库规定的格式，命令成功后可再次通过格式校验

#### Scenario: 开发者执行质量校验

- **WHEN** 开发者在有效的 Java 17 环境中执行独立质量校验命令
- **THEN** 命令 SHALL 同时验证格式与静态分析，并在任一问题存在时返回非零退出码和可定位的诊断信息

### Requirement: 提交前质量门禁

模板 SHALL 提供受版本控制的 pre-commit hook 及明确的本地安装入口，使开发者可在不手工复制 hook 内容的情况下启用提交前校验。

#### Scenario: 提交前检查通过

- **WHEN** 开发者已安装 hook，且待提交状态通过格式和静态分析校验
- **THEN** Git SHALL 允许本次提交继续执行

#### Scenario: 提交前检查失败

- **WHEN** 开发者已安装 hook，且质量校验发现问题或无法执行
- **THEN** hook SHALL 中止本次提交并输出可执行的修复或诊断命令

### Requirement: 远端质量校验

模板 SHALL 提供 GitHub Actions 工作流，在所有拉取请求以及 GitHub 默认分支 `master` 的推送上执行与本地独立质量入口等价的格式和静态分析校验。

#### Scenario: 拉取请求更新

- **WHEN** 用户创建、重新打开或更新任意目标分支的拉取请求
- **THEN** GitHub Actions SHALL 运行质量校验并将成功或失败状态反馈到该拉取请求

#### Scenario: 默认分支推送

- **WHEN** 代码被推送到 `master`
- **THEN** GitHub Actions SHALL 运行质量校验并将运行结果记录在该提交上

#### Scenario: 远端质量问题

- **WHEN** 远端格式或静态分析校验发现问题
- **THEN** 工作流 SHALL 以失败状态结束，且日志 SHALL 标明失败的校验类别

### Requirement: 质量工具使用说明

模板文档 SHALL 说明格式化、独立质量校验、hook 安装的命令与用途，并说明 GitHub Actions 在 PR 和 `master` 推送时的触发范围。

#### Scenario: 新贡献者配置本地门禁

- **WHEN** 新贡献者按 README 的质量门禁说明操作
- **THEN** 其能够完成 hook 安装、执行格式化并在本地执行与远端等价的质量校验
