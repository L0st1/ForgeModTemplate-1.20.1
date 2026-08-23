---
name: forge-mod-development
description: Develop, extend, diagnose, and verify Minecraft Forge 1.20.1 mods created from this template. Use for sided code, Forge events and registries, configuration, networking, Mixins, GameTest, local runs, and JAR builds; do not use for Fabric, NeoForge, or version upgrades.
---

# Forge Mod Development

Work from the generated project's actual `gradle.properties`, `mods.toml`, source tree, and enabled module flags. Keep user-requested behavior in scope and preserve unrelated Mod mechanics.

## Architecture decisions

1. Classify every behavior as common, client-only, or server-authoritative before editing. Read [references/sides.md](references/sides.md) when client classes, input, rendering, player state, inventories, damage, or world changes are involved.
2. Prefer Forge registries, events, capabilities, configuration, and data files when they expose the needed extension point. Use a Mixin only for hard-coded or external behavior without a stable Forge hook; read [references/mixin-and-network.md](references/mixin-and-network.md) first.
3. Treat the server as authoritative for gameplay state. A client key press that changes gameplay must send a direction-checked packet and validate the sender on the server.
4. Keep optional module configuration coherent: Java sources, resources, Gradle flags, Mixin manifests, and language keys must be added or removed together.

## Workflow

- Read [references/baseline.md](references/baseline.md) when checking versions, metadata sources, proxy behavior, or project layout.
- Inspect target APIs before coding. For add-ons, use the exact dependency version and confirm names/signatures rather than guessing.
- Implement the smallest coherent change and add a focused GameTest when the behavior can run without a full client.
- Run `scripts/doctor.ps1`, then `scripts/build-local.ps1`. For sided changes, also perform the relevant client or dedicated-server smoke check described in [references/verification.md](references/verification.md).
- Report the built JAR path and distinguish code failures from proxy, dependency, or local environment failures.

Do not deploy into a live game instance, publish a release, or modify third-party JARs unless the user explicitly requests that external action.
