#!/bin/bash

#############################################
# Usage:
#   1. ./check_floating_ip.sh
#   2. ./check_floating_ip project_name
############################################

project_names=("GuangHui_Li"  
		"Juan_Wu"
		"JingXian_Wu"
		"RuiQi_Sun"
		"XiaoLei_Han"
		"XiaoLi_Song"
		"Xu_Wang"
		"XueQiang_Li"
		"ZengHui_Jiao"
		"ZengHui_Guan"
		"Zhan_Gao"
)

if [ $# -eq 1 ]; then
	export OS_PROJECT_NAME=$1
	echo "$1: Floating IPs"
	nova floating-ip-list
	exit 0
fi

for name in ${project_names[*]}
do
	project_name=`echo $name | tr "_" " "`
	echo $project_name
	export OS_PROJECT_NAME=$project_name
	nova floating-ip-list
done
