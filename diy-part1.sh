#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
#echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
#echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default

# Add custom packages
mkdir -p package/custom

git clone --depth 1 -b master https://github.com/eamonxg/luci-theme-aurora.git package/custom/luci-theme-aurora || exit 1
git clone --depth 1 -b master https://github.com/eamonxg/luci-app-aurora-config.git package/custom/luci-app-aurora-config || exit 1
git clone --depth 1 -b main https://github.com/mrjoechen/luci-theme-carbon.git package/custom/luci-theme-carbon || exit 1
git clone --depth 1 -b main https://github.com/timsaya/openwrt-bandix.git package/custom/openwrt-bandix || exit 1
git clone --depth 1 -b main https://github.com/timsaya/luci-app-bandix.git package/custom/luci-app-bandix || exit 1
git clone --depth 1 -b main https://github.com/luanmuc/luci-app-airoha-npu.git package/custom/luci-app-airoha-npu || exit 1
