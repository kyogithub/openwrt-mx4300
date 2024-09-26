#!/bin/sh

mkdir kmod
cp bin/targets/qualcommax/ipq807x/packages/Packages* kmod
cp bin/targets/qualcommax/ipq807x/packages/kmod-* kmod
tar cfz kmod.tar.gz kmod/
