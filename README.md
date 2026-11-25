![精简自用，请自己 FORK 后编译固件!!!](assets/fork-build-warning.svg)

# Nokia XG-040G-MD 精简版 PonWrt 固件

仅编译 **Nokia XG-040G-MD（UBI）**，基于 Airoha AN7581 平台。构建源码使用 [1018ji/ponwrt](https://github.com/1018ji/ponwrt) 的 `master` 分支。

以 PON 管理和基础路由功能为核心，保留 IPv6、LuCI 中文界面及必要的系统工具，并按自用需求扩展硬件加速管理、流量统计、网络代理、文件共享和 USB/存储功能。使用 APK 软件包管理器。

![PonWrt 状态页面预览，包含 CPU/PON 温度显示](assets/ponwrt-status-preview-20261023.png)

## 主要调整

| 项目 | 当前配置 |
| --- | --- |
| 镜像 | Initramfs 使用 ZSTD 压缩，保留 SquashFS 根文件系统 |
| 设备功能 | 保留 PON 管理，精简无线功能 |
| USB 与存储 | 显式启用 USB 3.0、USB Storage、UAS、block-mount，以及 EXT4、exFAT、FAT32 和相关字符编码模块 |
| 网络扩展 | 集成 Nikki、OpenClash、ZeroTier、UPnP、ARP 绑定及网络唤醒 |
| DNS/DHCP | 使用 dnsmasq-full，保留 DHCP、DHCPv6、nftset；关闭 DNSSEC、权威 DNS、conntrack 和 TFTP 扩展 |
| 加密与 TLS | 启用 OpenSSL 速度及汇编优化、ChaCha20-Poly1305 优先策略，保留旧版 API 兼容；精简错误信息、ENGINE 及部分旧算法 |
| SSH | 使用 Dropbear SSH 服务，精简 SSH 客户端及部分转发功能 |
| 内核与工具 | 精简 Swap、namespace 和部分 cgroup；关闭 `procd-ujail`，保留 `procd-seccomp`；集成 htop、coremark 和 wakeonlan |
| LuCI | 集成 Bootstrap、Aurora、Carbon 主题及 Aurora 配置插件，移除「插件」「诊断」菜单 |
| 状态信息 | 显示 CPU/PON 温度、总 CPU 与每核使用率、PPE 流表已绑定/统计条目数；架构信息仅显示 CPU 架构和核心数 |
| 默认设置 | 集成 default-settings、default-settings-chn，初始化 LuCI 自动语言、中国时区及 NTP；默认 APK 镜像为 `https://mirror.nju.edu.cn/immortalwrt`（已有镜像配置时优先保留） |
| 其他 | 最大连接数设为 `30000`，启用 BusyBox `usleep` |

### 主要 LuCI 插件

| 分类 | 软件包 |
| --- | --- |
| 光猫与硬件加速 | `luci-app-pon`、`luci-app-airoha-npu` |
| 流量统计 | `luci-app-bandix` |
| 网络代理与组网 | `luci-app-nikki`、`luci-app-openclash`、`luci-app-zerotier` |
| 网络工具 | `luci-app-arpbind`、`luci-app-upnp`、`luci-app-wol` |
| 文件与存储 | `luci-app-filemanager`、`luci-app-ksmbd`（NAS 菜单） |
| 系统工具 | `luci-app-store`、`luci-app-ramfree`、`luci-app-ttyd` |

当前未启用 QuickStart，nas 和 nas_luci feeds 已注释。

### 精简功能与依赖

- 内核未保留完整容器支持；如需 Docker/LXC 或 `procd-ujail`，需恢复相应配置。
- 未主动选择 WireGuard、OpenVPN DCO、`ethtool-full`、`iperf3` 和 `tcpdump` 等软件包，可按需启用。
- OpenClash、Nikki 所需的 TUN、TPROXY、Socket 匹配等模块由软件包依赖及 `make defconfig` 处理；未主动选择不代表最终固件不包含这些依赖。
- 自定义 feeds 见 [`feeds.conf.default`](feeds.conf.default)，额外主题、Bandix 和 Airoha NPU 插件通过 [`diy-part1.sh`](diy-part1.sh) 拉取至 `package/custom/`。

上述内容以仓库当前选择及目标设备默认包为准，最终依赖和软件包清单由 `make defconfig` 及实际构建确定。完整编译选项见 [`.config`](.config)。

## 编译与下载

1. Fork 本仓库。
2. 在 **Actions → PonWrt Builder → Run workflow** 选择 SSH、Cache 选项并运行。
3. 成功后到 **Releases** 下载 `.itb` 固件及 `sha256sums`、`config.buildinfo`。失败时到当次运行的 **Artifacts** 查看 `build-logs`。

[构建工作流](.github/workflows/ponwrt-builder.yml) 同一时间只运行一个任务，后续任务排队。Releases 以北京时间命名，与 Actions 运行记录均保留最新 7 条。

### SSH

默认选择「否」。选择「是」后，从 **Setup SSH session** 步骤日志复制连接命令，后台编译会继续运行。仅允许触发任务的账号使用其 GitHub 公钥连接，需先在 **Settings → SSH and GPG keys** 配置公钥。源码目录为 `/workdir/openwrt`，调试完成后执行 `exit` 关闭会话。

### Cache

| 选项 | 缓存行为 | 用途 |
| --- | --- | --- |
| 使用缓存（默认） | 恢复并保存 | 日常编译 |
| 只读缓存 | 仅恢复，不保存 | 临时测试 |
| 重新编译 | 仅恢复下载缓存，重新编译并保存其他缓存 | 缓存损坏或需要重建 |
| 不使用缓存 | 不恢复、不保存 | 排查缓存问题 |

缓存分为下载包、工具链和 ccache 三类，每类保留最新一份。启用缓存保存时，编译失败后也会尝试保存 ccache，便于重试。可在 **Actions → Caches** 查看或删除缓存。外部触发（`repository_dispatch`）按「使用缓存」处理。

## DHCP 租约主机名

点击 DHCPv4 租约主机名旁的铅笔设置显示名称，按 MAC 关联，支持汉字、英文字母、数字、普通空格、`-`、`_`，最多 32 个字符；首尾空格自动去除，留空恢复原名。DHCPv6 租约按同一 MAC 复用该名称，不提供单独编辑；MAC 依次取自租约本身、DUID-LLT/DUID-LL、仅含单个 MAC 的静态租约（先匹配 `DUID%IAID` 再匹配 DUID）；无法识别 MAC 或未设置名称时，继续显示原主机名。不修改 DNS 或 DHCP 地址分配。

保存后先暂存，IPv4、IPv6 租约表同步显示新名字。在原生更改窗口中，「关闭」保留暂存，「恢复」撤销待应用修改，「保存并应用」持久保存；应用时可能同时处理其他页面的待应用修改。

DHCP 租约主机名功能由 [LuCI 补丁](patches/feeds/luci) 实现。已有编译产物时，修改该补丁后应清理并重新编译 `luci-base`（含中文翻译）和 `luci-mod-status`。

## 补丁管理

工作流使用统一的 [`scripts/apply-patches.sh`](scripts/apply-patches.sh)，在拉取主源码后、更新 feeds 前应用主源码补丁，并在更新 feeds 后、安装 feeds 前应用各 feed 补丁。

本地构建时，在对应阶段运行以下命令：

```sh
# 拉取 OpenWrt 源码后、更新 feeds 前
./scripts/apply-patches.sh source /path/to/openwrt

# 更新 feeds 后、安装 feeds 前
./scripts/apply-patches.sh feeds /path/to/openwrt/feeds
```

主源码补丁位于 `patches/openwrt/`，各 feed 的补丁位于 `patches/feeds/<feed>/`。仅处理 `.patch` 文件，禁用的补丁会跳过。每个源码或 feed 目录独立检查并应用整组补丁；已完整应用的补丁会跳过，冲突或部分应用时停止，不自动重置或丢弃已有修改。上游更新导致冲突时，需适配补丁后重试。
