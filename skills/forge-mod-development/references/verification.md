# 验证清单

1. 运行 `powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1`，确认 Java 17、Wrapper、关键文件与代理模式。
2. 运行 `powershell -ExecutionPolicy Bypass -File .\scripts\build-local.ps1`，执行可用的格式检查、测试和 `build`。
3. 检查 `build/libs/<mod_id>-<mod_version>.jar`，确认 `META-INF/mods.toml`、资源命名空间和可选 Mixin manifest。
4. 客户端代码变更运行 `gradlew runClient` 冒烟检查，观察 Mod 加载与日志错误。
5. 公共端、网络或权威状态变更运行 `gradlew runServer --args --nogui` 或等价专用服务器检查，至少推进到 Mod 构造完成。
6. GameTest 模块启用时运行对应 GameTest server 任务。

不要把网络下载失败、代理不可达或 JDK 不兼容误报为源码回归；报告时分别给出环境证据与代码验证结果。
