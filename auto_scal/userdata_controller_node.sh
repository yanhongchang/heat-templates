#!/bin/bash

## Author: 	Jeffrey Guan
## Name: 	userdata_controller_node.sh
## Date: 	2016-09-01
## Note: 	userdata file for controller node.
## Version: 	v1.0

# get the NICs MAC address.
ETH0_MAC_ADDRESS=`cat /sys/class/net/eth0/address`
ETH1_MAC_ADDRESS=`cat /sys/class/net/eth1/address`
ETH2_MAC_ADDRESS=`cat /sys/class/net/eth2/address`
ETH3_MAC_ADDRESS=`cat /sys/class/net/eth3/address`
ETH4_MAC_ADDRESS=`cat /sys/class/net/eth4/address`

NIC_DIR="/etc/network/interfaces.d/"

##################################################
#		Start add bridges		 #
##################################################

# br-fw-admin: setup br-fw-admin
touch ${NIC_DIR}/ifcfg-fw-admin
cat >>${NIC_DIR}/ifcfg-br-fw-admin <<EOF
auto br-fw-admin
iface br-fw-admin inet dhcp
bridge-ports eth0
EOF

# br-storage: set br-storage's mac address and setup the route.
touch ${NIC_DIR}/ifcfg-storage
cat >> ${NIC_DIR}/ifcfg-br-storage <<EOF
auto br-storage
iface br-storage inet dhcp
bridge-ports eth1
EOF

# br-ex: create and update the br-ex config file.
touch ${NIC_DIR}/ifcfg-br-ex
cat >> ${NIC_DIR}/ifcfg-br-ex <<EOF
auto br-ex
iface br-ex inet dhcp
bridge-ports eth2 p_ff798dba-0
EOF
sed -i "/^pre-up/d" ${NIC_DIR}/ifcfg-br-ex 
eth2_hw_str="pre-up ifconfig br-ex hw ether ${ETH2_MAC_ADDRESS}"
sed -i "/^iface/a\\${eth2_hw_str}" ${NIC_DIR}/ifcfg-br-ex 

# br-mgmt: 
touch ${NIC_DIR}/ifcfg-br-mgmt
cat >> ${NIC_DIR}/ifcfg-br-mgmt <<EOF
auto br-mgmt
iface br-mgmt inet dhcp
bridge-ports eth3
EOF
sed -i "/^up route add/d" /etc/rc.local
sed -i "/^ifconfig br-mgmt/d" /etc/rc.local
sed -i "/^$/d" /etc/rc.local
cat >>/etc/rc.local <<EOF
ifconfig br-mgmt down
ifconfig br-mgmt hw ether ${ETH3_MAC_ADDRESS}
ifconfig br-mgmt up

route add default gw 192.168.100.1
EOF

# br-mesh: set route for 169.254.169.254
touch ${NIC_DIR}/ifcfg-br-mesh
cat >> ${NIC_DIR}/ifcfg-br-mesh <<EOF
auto br-mesh
iface br-mesh inet dhcp
bridge-ports eth4
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


