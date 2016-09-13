#!/bin/bash

## Author: 	Jeffrey Guan
## Name: 	userdata_compute_node.sh
## Date: 	2016-09-01
## Note: 	userdata file for compute node.
## Version: 	v1.0

# get the NICs MAC address.
ETH0_MAC_ADDRESS=`cat /sys/class/net/eth0/address`
ETH1_MAC_ADDRESS=`cat /sys/class/net/eth1/address`
ETH2_MAC_ADDRESS=`cat /sys/class/net/eth2/address`
ETH3_MAC_ADDRESS=`cat /sys/class/net/eth3/address`

NIC_DIR="/etc/network/interfaces.d"

# add bridges.		 
# usage: set_bridges $default_gw_br-mgmt
function set_bridges()
{
  # br-fw-admin: setup br-fw-admin.
  touch ${NIC_DIR}/ifcfg-br-fw-admin
  cat > ${NIC_DIR}/ifcfg-br-fw-admin <<EOF
auto br-fw-admin
iface br-fw-admin inet dhcp
bridge-ports eth0
EOF

  # br-storage: set br-storage's mac address and setup the route.
  touch ${NIC_DIR}/ifcfg-br-storage
  cat > ${NIC_DIR}/ifcfg-br-storage <<EOF
auto br-storage
iface br-storage inet dhcp
bridge-ports eth1
EOF

  # br-mgmt: 
  touch ${NIC_DIR}/ifcfg-br-mgmt
  cat > ${NIC_DIR}/ifcfg-br-mgmt <<EOF
auto br-mgmt
iface br-mgmt inet dhcp
bridge-ports eth2
EOF

  # br-mesh: set route for 169.254.169.254.
  touch ${NIC_DIR}/ifcfg-br-mesh
  cat > ${NIC_DIR}/ifcfg-br-mesh <<EOF
auto br-mesh
iface br-mesh inet dhcp
bridge-ports eth3
up route add -host 169.254.169.254 dev br-mesh
EOF

}

# setup NICs.		 
function set_NIC()
{
  # set "dhcp" to "manual" for eth0~eth4.
  for i in `ls ${NIC_DIR}/*eth*`
  do
    sed -i "s/dhcp/manual/" $i
  done  
}

# setup hostname.
function set_hostname()
{
  cat > /etc/hostname <<EOF
${1}.domain.tld
EOF
}

# reboot the VM to setup the NICs.
function rebootVM()
{
  while true
  do
    echo "Please wait for the NICs going ready..."

    if [ -f "${NIC_DIR}/ifcfg-br-mgmt" ]; then
      if [ ! -f "/home/lock.file" ]; then
        touch /home/lock.file
        reboot
      fi

      break

    fi
  done

  echo "Successfully setup the NICs..."
}

function install_ceph_client()
{
  sed -i "s/10.20.0.9/$CEPH_FIXED_IP/g" /etc/ceph/ceph.conf
  python /home/sdx@10.100.218.73/install-cephclient.py compute
}

function setup_nova_conf()
{
  echo "will add..."
}

################################################
#		  MAIN			       #
################################################
set_bridges $DEFAULT_GW_BR_MGMT

# add the br-mgmt's default gw into routing table.
sed -i "/flock/a\\up route add default gw $DEFAULT_GW_BR_MGMT" \
       /etc/rc.local

set_NIC
set_hostname $NAME

install_ceph_client && setup_nova_conf

# reboot vms in order to make above changes taking effect.
rebootVM

# exit safely.
exit 0


