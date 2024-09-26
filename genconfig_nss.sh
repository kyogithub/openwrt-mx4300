#!/bin/sh

cat nss-setup/config-nss.seed |  grep -v luci- > .config
echo  CONFIG_FEED_nss_packages=n >> .config
make defconfig


if [ "$1" = "full" ]; then
    kmods=$(wget -qO- https://downloads.openwrt.org/snapshots/targets/qualcommax/ipq807x/packages/Packages.manifest | grep "Package: kmod"  | grep -v ath | cut -d ' ' -f 2)
    for k in $kmods; do grep -q $k=y .config || echo CONFIG_PACKAGE_$k=m >> .config; done
    make defconfig
fi

