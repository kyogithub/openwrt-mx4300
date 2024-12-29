#!/bin/sh


if [ ! -z "$1" -a "$1" != "snapshot" ]; then
  buildinfo="https://downloads.openwrt.org/releases/$1/targets/qualcommax/ipq807x/config.buildinfo"
else
  buildinfo="https://downloads.openwrt.org/snapshots/targets/qualcommax/ipq807x/config.buildinfo"
fi

wget $buildinfo -O - | grep -v CONFIG_TARGET_DEVICE_ | grep -v CONFIG_TARGET_ALL_PROFILES | grep -v CONFIG_TARGET_MULTI_PROFILE > .config

echo "
CONFIG_TARGET_ALL_PROFILES=n 
CONFIG_TARGET_MULTI_PROFILE=n
CONFIG_TARGET_qualcommax_ipq807x_DEVICE_linksys_mx4300=y
CONFIG_TARGET_DEVICE_qualcommax_ipq807x_DEVICE_linksys_mx4300=y
CONFIG_TARGET_DEVICE_PACKAGES_qualcommax_ipq807x_DEVICE_linksys_mx4300=\"\"
CONFIG_PACKAGE_luci=y
" >> .config

#Custom Packages for Node Router 
echo "
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_kmod-usb-storage-uas=y
CONFIG_PACKAGE_luci-app-samba4=y
CONFIG_PACKAGE_fping=y
CONFIG_PACKAGE_coreutils-timeout=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_bash=y
CONFIG_PACKAGE_netdata=y
CONFIG_PACKAGE_arp-scan=y
CONFIG_PACKAGE_luci-compat=y
CONFIG_PACKAGE_luci-app-hd-idle=y
" >> .config

make defconfig

#add libpam
#echo CONFIG_PACKAGE_libpam=y >> .config

#skip xdp compile
#cat .config | grep -v "CONFIG_PACKAGE.*xdp" > .config.tmp
#cp .config.tmp .config
