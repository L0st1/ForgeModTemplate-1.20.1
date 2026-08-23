## Context

参见 `proposal.md`。当前模板基于 Java 17、Gradle 8.8 和 ForgeGradle，尚未配置格式化、静态分析、Git hook 或 GitHub Actions。质量门禁必须适用于 Git for Windows 和常见 Unix Git 环境，并避免为纯代码质量任务触发完整 Forge 编译与运行环境准备。

## Goals / Non-Goals

**Goals:**

- 以一个 Gradle 聚合任务提供可在本地 hook 与 CI 复用的质量校验入口。
- 固定、可复现地执行 Java 格式化检查和高置信静态分析。
- 将 hook 内容纳入版本控制，并提供安全的显式安装方式。
- 在 PR 与 `master` 推送上执行同一套远端校验。

**Non-Goals:**

- 不在本变更中添加单元测试、GameTest、完整构建或发布流水线。
- 不引入 Checkstyle、SpotBugs、Error Prone 或多套重叠的风格规则。
- 不自动修改开发者暂存区或在 hook 中运行格式化修复。
- 不改变初始化器、代理策略、Mod 运行时依赖或 Minecraft 版本基线。

## Decisions

### 使用 Spotless 作为唯一格式化工具

在 `build.gradle` 中接入 Spotless，并将格式范围限定为模板管理的 Java 源码；使用 `google-java-format` 统一空白、换行与 import 格式。公开 `spotlessApply` 供开发者修复，公开 `spotlessCheck` 供自动化验证。

选择原因：Spotless 可直接由 Gradle Wrapper 下载并执行，兼容本仓库的 Java 17 / Gradle 8.8 基线，且格式化规则不需要每位贡献者单独配置 IDE。

备选方案：仅依赖 IDE 设置无法保证一致性；Eclipse formatter 可高度定制，但需要维护格式配置；Prettier Java 方案会额外引入 Node 生态，因此不采用。

### 使用 Gradle 内置 PMD 进行最小静态分析

启用 Gradle 的 PMD 插件，版本显式锁定到与 Java 17 兼容的发行版，并仅使用 Java `errorprone` 规则类别中的高优先级规则。生产与测试源码均纳入分析；生成源码和构建输出不纳入范围。

选择原因：PMD 是 Gradle 原生支持的源代码分析器，不依赖 Forge 的编译产物，因此独立质量校验不必解析或启动完整游戏构建。高优先级错误规则能避免早期规则噪声。

备选方案：Checkstyle 偏重样式规则，与格式化器职责重叠；SpotBugs 要分析字节码并会增加 Forge 构建耦合；Error Prone 侵入 Java 编译链，因此均不作为初始门禁。

### 提供统一的 `qualityCheck` 任务并接入常规构建

定义 `qualityCheck` 聚合任务，使其依赖格式检查和 PMD 主/测试源码检查；同时将格式检查纳入 Gradle 的 `check` 生命周期，确保既有 `build` 入口不会绕过格式约束。hook、CI 与文档统一调用 `qualityCheck`，避免三处命令逐渐漂移。

选择原因：质量校验无需完整 Forge 编译即可提供快速反馈，而常规构建仍会包含所有质量检查。

### 使用版本化 Git hook，而非额外 hook 管理器

在 `.githooks/pre-commit` 保存 POSIX shell hook，通过 Gradle 的显式安装任务写入仓库本地 Git 配置的 `core.hooksPath`。安装任务在发现已有且不同的本地 hooks 路径时 SHALL 失败并提示人工处理，避免静默覆盖现有开发者配置。

hook 仅调用 `./gradlew qualityCheck` 并在失败时阻止提交；它不调用自动修复任务。该脚本可由 Git for Windows 的 shell 和 Unix shell 执行。

选择原因：无需安装 Python `pre-commit`、Node 或第三方 Gradle hook 插件，且 hook 内容能随模板版本演进。

备选方案：Python `pre-commit` 生态成熟但增加非 Java 工具链；直接复制到 `.git/hooks` 可能覆盖个人 hook；Spotless 内置的 pre-push hook 触发时机不满足提交前要求。

### 将远端质量工作流限定为 PR 与默认分支推送

新增 `.github/workflows/quality.yml`，使用 Java 17、Gradle Wrapper 和 Gradle 缓存执行 `qualityCheck`。工作流在未限定目标分支的 `pull_request` 事件及 `master` 的 `push` 事件上触发；工作流只授予读取仓库内容所需的最小权限。

选择原因：PR 事件覆盖功能分支提交的评审反馈，`master` 推送覆盖直接提交和合并结果，同时避免每次 PR 更新都因所有分支 `push` 而重复运行。未限制 PR 目标分支可兼容仓库的 Minecraft 版本维护分支。

备选方案：仅 `push` 会使 PR 质量状态不直观；所有分支 `push` 会与 PR 事件产生重复运行；仅 PR 会遗漏直接推送到默认分支。

## Risks / Trade-offs

- [首次运行需下载格式化器和 PMD] → 使用 Gradle Wrapper 与 CI Gradle 缓存；README 明确首次运行可能较慢。
- [`google-java-format` 会一次性重写现有 Java 文件] → 首次接入时单独提交纯格式化变更，避免与功能修改混合。
- [PMD 规则可能对 Forge API 用法产生误报] → 初始规则范围限于高优先级错误类别；确认误报后以最小范围抑制并记录理由。
- [本地 hook 需要开发者主动安装] → README 提供单一安装命令，并在质量命令说明中明确其作用范围。
- [默认分支未来改名] → Actions 的分支过滤需与 GitHub 默认分支同步更新；本提案基于已查询确认的 `master`。

## Migration Plan

1. 添加 Gradle 质量任务与版本化 hook、工作流和文档。
2. 运行格式化并将纯格式变更与工具接入一起提交。
3. 在干净克隆中执行 hook 安装与 `qualityCheck`，确认其不依赖未提交的本地配置。
4. 推送分支并验证 PR 与 `master` 推送均产生质量工作流；通过后将工作流检查设为 `master` 的合并必需检查。

回滚时移除 Gradle 质量配置、hook 与 workflow；对已设置的本地 `core.hooksPath`，文档提供恢复为默认 Git hooks 路径的命令。
