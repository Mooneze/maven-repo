# Mooneze Maven / NuGet packages

HMCL / PCL-CE 从 `HMCL-dev`、`PCL-Community` 拆出来的依赖制品，发布到这里，供构建时使用。

源码镜像在 `Mooneze` 组织下的对应仓库，默认分支是 `mooneze`。

## Maven

仓库地址：

```
https://maven.pkg.github.com/Mooneze/maven-repo
```

| 坐标 | 说明 |
|---|---|
| `org.glavo:hellonbt:0.4.0` | HelloNBT（原 `org.glavo:HelloNBT`） |
| `org.glavo.hmcl:hmclauncher:3.7.0.1` | HMCLauncher（原 `org.glavo.hmcl:HMCLauncher`） |
| `org.glavo:lwjgl-unsafe-agent:2.0` | lwjgl-unsafe-agent |
| `org.glavo:mesa-loader-windows:26.0.4` | mesa-loader-windows |

GitHub Packages 的 Maven 仓库不接受大写 artifactId，所以 `HelloNBT` 和 `HMCLauncher` 发布了小写版本，坐标也相应改成小写。

仓库是 public，但 GitHub Packages 的 Maven/NuGet **读取仍然需要 token**；匿名请求返回 401。token 需要 `read:packages` / `write:packages`（`write:packages` 已包含读取权限）。

## NuGet

源地址：

```
https://nuget.pkg.github.com/Mooneze/index.json
```

| 包 | 版本 |
|---|---|
| `PlainToolkit.CngProtectedData` | `2.1.0` |

## 发布

在 Actions 里手动运行 `Publish dependencies to GitHub Packages`，或者：

```bash
GITHUB_TOKEN=... GITHUB_ACTOR=RainC7 bash publish.sh
```

脚本会从 Maven Central / NuGet.org 拉取官方制品，修正 POM 里的 artifactId 和上游地址，然后发布到 GitHub Packages。

## 本地/离线

`HMCL-PCLCE-依赖清单.md` 里还保留了一套本地制品仓库（`mirrors/artifacts`），没有网络或没有 token 时优先使用它。
