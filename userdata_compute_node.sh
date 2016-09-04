#!/bin/bash

## Author: 	Jeffrey Guan
## Name: 	userdata_compute_node.sh
## Date: 	2016-09-01
## Note: 	userdata file for compute node.
## Version: 	v1.0

NIC_DIR="/etc/network/interfaces.d/"

##################################################
#		Start add bridges		 #
##################################################

# br-fw-admin: setup br-fw-admin
touch ${NIC_DIR}/ifcfg-br-fw-admin
cat >>${NIC_DIR}/ifcfg-br-fw-admin <<EOF
auto br-fw-admin
iface br-fw-admin inet dhcp
bridge-ports eth0
EOF

# br-storage: set br-storage's mac address and setup the route.
touch ${NIC_DIR}/ifcfg-br-storage
cat >> ${NIC_DIR}/ifcfg-br-storage <<EOF
auto br-storage
iface br-storage inet dhcp
bridge-ports eth1
EOF

# br-mgmt: 
touch ${NIC_DIR}/ifcfg-br-mgmt
cat >> ${NIC_DIR}/ifcfg-br-mgmt <<EOF
auto br-mgmt
iface br-mgmt inet dhcp
bridge-ports eth2
EOF
sed -i "/^up route add/d" /etc/rc.local
sed -i "/^ifconfig br-mgmt/d" /etc/rc.local
sed -i "/^$/d" /etc/rc.local

# br-mesh: set route for 169.254.169.254
touch ${NIC_DIR}/ifcfg-br-mesh
cat >> ${NIC_DIR}/ifcfg-br-mesh <<EOF
auto br-mesh
iface br-mesh inet dhcp
bridge-ports eth3
EOF
sed -i "/^up route/d" ${NIC_DIR}/ifcfg-br-mesh
sed -i "/^$/d" ${NIC_DIR}/ifcfg-br-mesh
cat >>${NIC_DIR}/ifcfg-br-mesh <<EOF
up route add -host 169.254.169.254 dev br-mesh
EOF
##################################################
#		End add bridges		         #
##################################################


##################################################
#		Begin setup NICs		 #
##################################################

# set "dhcp" to "manual" for eth0~eth4.
for i in `ls *eth*`; do
  sed -i "s/dhcp/manual/" $i
done  
##################################################
#		End setup NICs			 #
##################################################

exit 0


