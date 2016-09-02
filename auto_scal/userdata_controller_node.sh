#!/bin/bash

## Author:      Jeffrey Guan
## Name:        userdata_controller_node.sh
## Date:        2016-09-01
## Note:        userdata file for controller node.
## Version:     v1.0

ETH2_MAC_ADDRESS=`cat /sys/class/net/eth2/address`
ETH3_MAC_ADDRESS=`cat /sys/class/net/eth3/address`
NIC_DIR="/etc/network/interfaces.d/"

# update the br-ex config file.
sed -i "/^pre-up/d" ${NIC_DIR}/ifcfg-br-ex
eth2_hw_str="pre-up ifconfig br-ex hw ether ${ETH2_MAC_ADDRESS}"
sed -i "/^iface/a\\${eth2_hw_str}" ${NIC_DIR}/ifcfg-br-ex

# set br-mgmt's mac address and setup the route.
sed -i "/^up route add/d" /etc/rc.local
sed -i "/^ifconfig br-mgmt/d" /etc/rc.local
cat >>/etc/rc.local <<EOF
ifconfig br-mgmt down
ifconfig br-mgmt hw ether ${ETH3_MAC_ADDRESS}
ifconfig br-mgmt up

route add default gw 192.168.100.1
EOF

# set route for 169.254.169.254
sed -i "/^up route/d" ${NIC_DIR}/ifcfg-br-mesh
cat >>${NIC_DIR}/ifcfg-br-mesh <<EOF
up route add -host 169.254.169.254 dev br-mesh
EOF

sudo reboot

exit 0
