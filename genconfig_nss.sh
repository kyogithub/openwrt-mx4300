#!/bin/sh

cp nss-setup/config-nss.seed .config

echo CONFIG_ATH11K_THERMAL=y >> .config
echo CONFIG_KMOD_ALL=y >> .config

make defconfig
