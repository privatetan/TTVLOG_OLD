#!/bin/bash

msg=$1
if [ -n "$msg" ]; then
	cd /Users/privatetan/Documents/TTVLOG
	git add . 
	git commit -m "$msg"
	git pull
	echo "完成add、commit pull操作"
        git push
	echo "完成push操作"
else
	echo "请添加注释再来一遍"
fi


