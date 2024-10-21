#!/bin/bash

sed -i '$a src-git luciargon https://github.com/jerrykuku/luci-theme-argon.git;master' feeds.conf.default
#echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
