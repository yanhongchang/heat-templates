#!/bin/bash

#####################################################
# Usage:
#   ./bulk_delete_floating_ips.sh project_nme saved_ip2
#   expect saved_ip1, others will be deleted
#####################################################
if [ $# -ne 2 ]; then
	echo "#####################################"
	echo "# Usage:"
	echo "# "
	echo "# ./bulk_delete_floating_ips.sh project_nme saved_ip2"
	echo "# "
	echo "#####################################"
	
	exit 0
fi

floating_ips=$(nova floating-ip-list | cut -d "|" -f 3 | grep '[0-9]')

export OS_PROJECT_NAME=$1

for del_ip in $floating_ips
do
	if [ $del_ip == $2 ]; then
		continue
	else
		echo "deleting $del_ip"
		nova floating-ip-delete $del_ip
	fi
done

