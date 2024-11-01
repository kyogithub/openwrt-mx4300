#!/bin/sh

MD="note.md"
mkdir release
cp  bin/targets/qualcommax/ipq807x/openwrt-qualcommax-ipq807x-linksys_mx4300-* release/
cp  bin/targets/qualcommax/ipq807x/openwrt-qualcommax-ipq807x-linksys_mx4300.manifest release/
cp bin/targets/qualcommax/ipq807x/openwrt-imagebuilder* release/
kernel=$(cat release/openwrt-qualcommax-ipq807x-linksys_mx4300.manifest | grep ^kernel)
checksum=$(sha256sum release/* | sed 's/release\///')
#echo $checksum
echo "- $kernel

- sha256sum
\`\`\`
$checksum
\`\`\`

- \"pkg_hash_check_unresolved: cannot find dependency kernel\" [fix](https://github.com/arix00/openwrt-mx4300/blob/doc/snapshot-dependency-guide.md)" > $MD
