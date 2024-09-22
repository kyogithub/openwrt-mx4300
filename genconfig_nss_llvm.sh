#!/bin/sh

wget  https://downloads.openwrt.org/snapshots/targets/qualcommax/ipq807x/config.buildinfo -O config.buildinfo
cat config.buildinfo | grep -v CONFIG_TARGET_ | grep -v CONFIG_IB | grep -v ONFIG_PACKAGE > .config

cat nss-setup/config-nss.seed | grep -v CONFIG_TARGET_OPTIMIZATION | grep -v CONFIG_CCACHE >> .config
echo CONFIG_ATH11K_THERMAL=y >> .config
echo CONFIG_ALL_KMODS=y >> .config

grep -q CONFIG_NF_CONNTRACK_DSCPREMARK_EXT target/linux/generic/config-6.6 || echo "# CONFIG_NF_CONNTRACK_DSCPREMARK_EXT is not set" >> target/linux/generic/config-6.6
make defconfig

echo "CONFIG_PACKAGE_kmod-ath10k=n
CONFIG_ATH10K_LEDS=n
CONFIG_ATH10K_THERMAL=n
CONFIG_PACKAGE_kmod-ath10k-ct=n
CONFIG_ATH10K-CT_LEDS=n
CONFIG_PACKAGE_kmod-ath10k-ct-smallbuffers=n
CONFIG_PACKAGE_kmod-ath10k-smallbuffers=n"  >> .config

cat .config | grep -v CONFIG_ALL_KMODS  > .config.tmp
cp .config.tmp .config

make defconfig
