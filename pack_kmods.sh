#!/bin/sh

mkdir kmods
cp bin/targets/qualcommax/ipq807x/packages/Packages* kmods
cp bin/targets/qualcommax/ipq807x/packages/kmod-* kmods
tar cfz kmods.tar.gz kmods/
