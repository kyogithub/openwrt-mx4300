#!/bin/sh

cp nss-setup/config-nss.seed .config

echo CONFIG_ATH11K_THERMAL=y >> .config
echo CONFIG_KMOD_ALL=y >> .config
echo CONFIG_ATH10K=n >> .config
echo "# CONFIG_NF_CONNTRACK_DSCPREMARK_EXT is not set" >> target/linux/generic/config-6.6

make defconfig
