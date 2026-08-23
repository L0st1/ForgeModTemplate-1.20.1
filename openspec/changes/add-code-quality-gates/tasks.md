## 1. Gradle 质量任务

- [x] 1.1 在 `build.gradle` 中接入与 Java 17、Gradle 8.8 兼容且版本固定的 Spotless 与 PMD 配置，限定 Java 源码范围并启用高优先级 `errorprone` 分析规则。
- [x] 1.2 添加 `qualityCheck` 聚合任务，使其执行格式检查和主/测试源码 PMD 检查，并将格式检查接入现有 `check` 生命周期。
- [x] 1.3 执行格式化入口并验证 `./gradlew qualityCheck` 成功；为格式或 PMD 故意制造一个可恢复的违规，确认任务失败且诊断可定位。

## 2. 本地提交门禁

- [x] 2.1 添加受版本控制的 `.githooks/pre-commit`，使其调用 Gradle `qualityCheck`、在失败时中止提交并给出格式化或诊断提示。
- [x] 2.2 添加 Gradle hook 安装任务：安全设置仓库本地 hooks 路径，并在检测到冲突的既有本地设置时停止且说明处理方式。
- [x] 2.3 在隔离 Git 克隆中执行安装任务，分别验证质量通过时可提交、质量失败时提交被 hook 阻止，以及自动格式化不会由 hook 隐式执行。

## 3. GitHub Actions 质量校验

- [x] 3.1 新增最小权限的 `.github/workflows/quality.yml`，使用 Java 17、Gradle Wrapper 与 Gradle 缓存执行 `qualityCheck`。
- [x] 3.2 配置工作流在所有 `pull_request` 更新及 `master` 推送时触发，并检查 YAML 与 Gradle 命令可被 GitHub Actions runner 执行。
- [ ] 3.3 推送测试分支并验证 PR 产生质量状态；合并或向 `master` 推送后验证提交也产生质量状态，将该检查配置为 `master` 的必需合并检查。

## 4. 开发文档与回归验证

- [x] 4.1 在 `README.md` 中说明格式化、`qualityCheck`、hook 安装/卸载、首次下载耗时以及 PR 与 `master` 的 CI 触发范围。
- [x] 4.2 运行现有 PowerShell 测试与 `./gradlew build`，确认质量门禁未破坏模板初始化、代理配置或标准构建入口。
- [x] 4.3 审查变更范围，确认不提交构建产物、Gradle 缓存、PMD 报告或本地 Git 配置，并记录最终验证结果。
