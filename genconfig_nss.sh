#!/bin/sh

cp nss-setup/config-nss.seed .config

echo CONFIG_ATH11K_THERMAL=y >> .config
echo CONFIG_KMOD_ALL=y >> .config
echo "# CONFIG_NF_CONNTRACK_DSCPREMARK_EXT is not set" >> target/linux/generic/config-6.6

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
