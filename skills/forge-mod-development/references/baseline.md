# 项目基线

- Minecraft：1.20.1。
- Forge：47.4.0。
- Java toolchain：17。
- Gradle Wrapper：8.8。
- 项目身份与版本的规范来源是根目录 `gradle.properties`。
- `build.gradle` 在 `processResources` 阶段展开 `mods.toml` 和 `pack.mcmeta`。
- `config/network.properties` 提供默认代理；`config/network.local.properties` 和 `MC_MOD_PROXY_*` 环境变量用于本地覆盖。
- `enable_mixin`、`enable_config`、`enable_network`、`enable_gametest` 表示初始化时启用的可选模块。

修改版本或元数据时只调整规范来源，并检查生成 JAR 内部值，不要在多个文件中维护互相独立的副本。
