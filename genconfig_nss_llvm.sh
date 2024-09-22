#!/bin/sh

cat nss-setup/config-nss.seed | grep -v CONFIG_TARGET_OPTIMIZATION | grep -v CONFIG_CCACHE > .config
echo CONFIG_ATH11K_THERMAL=y >> .config
echo CONFIG_ALL_KMODS=y >> .config
echo CONFIG_ATH10K=n >> .config

wget  https://downloads.openwrt.org/snapshots/targets/qualcommax/ipq807x/config.buildinfo -O config.buildinfo
cat config.buildinfo | grep -v CONFIG_TARGET_ | grep -v CONFIG_IB | grep -v ONFIG_PACKAGE >> .config

make defconfig

#skip xdp
cat .config | grep -v "CONFIG_PACKAGE.*xdp" > .config.tmp
cp .config.tmp .config
