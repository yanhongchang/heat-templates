#!/bin/bash

#######################################
# Usage:
#
# ./create_floating_ip.sh project_name
#######################################

if [ $# -ne 1 ]; then
	echo "#####################################"
	echo "# Usage:"
	echo "#"
	echo "#./create_floating_ip.sh project_name"
	echo "#"
	echo "#####################################"
	
	exit 0
fi
	
export OS_PROJECT_NAME=$1
export OS_TENANT_NAME=$1

nova floating-ip-create net04_external
