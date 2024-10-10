#!/bin/sh

wget -qO- https://downloads.openwrt.org/snapshots/targets/qualcommax/ipq807x/config.buildinfo | grep -v CONFIG_TARGET_DEVICE_ | grep -v CONFIG_TARGET_ALL_PROFILES | grep -v CONFIG_TARGET_MULTI_PROFILE > .config
echo CONFIG_TARGET_ALL_PROFILES=n >> .config
echo CONFIG_TARGET_MULTI_PROFILE=n >> .config
echo CONFIG_TARGET_qualcommax_ipq807x_DEVICE_linksys_mx4300=y >> .config
echo CONFIG_TARGET_DEVICE_qualcommax_ipq807x_DEVICE_linksys_mx4300=y >> .config
echo CONFIG_TARGET_DEVICE_PACKAGES_qualcommax_ipq807x_DEVICE_linksys_mx4300=\"\" >> .config
#add luci
echo CONFIG_PACKAGE_luci=y >> .config

#add extras
echo CONFIG_PACKAGE_block-mount=y >> .config
echo CONFIG_PACKAGE_luci-app-samba4=y >> .config
echo CONFIG_PACKAGE_luci-app-ddns=y >> .config
echo CONFIG_PACKAGE_ddns-scripts-noip=y >> .config
echo CONFIG_PACKAGE_luci-proto-wireguard=y >> .config
echo CONFIG_PACKAGE_kmod-wireguard=y >> .config
echo CONFIG_PACKAGE_wireguard-tools=y >> .config
echo CONFIG_PACKAGE_luci-app-pbr=y >> .config
echo CONFIG_PACKAGE_fping=y >> .config
echo CONFIG_PACKAGE_arp-scan=y >> .config
echo CONFIG_PACKAGE_luci-theme-argon=y >> .config
make defconfig

#add libpam
#echo CONFIG_PACKAGE_libpam=y >> .config

#skip xdp compile
cat .config | grep -v "CONFIG_PACKAGE.*xdp" > .config.tmp
cp .config.tmp .config

