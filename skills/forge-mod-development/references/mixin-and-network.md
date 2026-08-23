# Mixin 与网络选择

## 何时使用 Mixin

仅在配置、数据包、Forge 事件、注册器或公开 API 无法表达需求时使用。实施前确认目标类、方法描述符、映射空间和依赖版本。优先使用 `@Inject` 等局部注入，避免 `@Overwrite`；外部 Mod 目标通常需要明确 `remap` 策略。

启用 Mixin 时同步检查：

- `enable_mixin=true`；
- annotation processor；
- `*.mixins.json`、package 与 refmap；
- JAR manifest 的 `MixinConfigs`；
- 目标 Mod 缺失或版本变化时的失败方式。

## 何时使用网络

客户端输入需要影响服务端权威状态时使用 C2S 消息；服务端状态需要主动呈现时使用 S2C 消息。每种消息固定方向、协议版本和唯一 ID。处理器先验证 sender 与参数，再通过 `enqueueWork` 修改状态，最后标记 packet handled。
