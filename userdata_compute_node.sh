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
  sed -i "s/vms88/$1/g" /etc/nova/nova.conf
}

# add the compute nodes' ip and domain in /etc/hosts.
function setup_hosts()
{
  sed -i "/node-372/d" /etc/hosts
  sed -i "/node-373/d" /etc/hosts

  let i=0 

  while [ $i -lt $1 ]
  do
  cat >> /etc/hosts <<EOF
192.168.121.1$i    host-${i}.domain.tld     host-$i
EOF
  
  let i=i+1
  done
}

################################################
#		  MAIN			       #
################################################
set_bridges $DEFAULT_GW_BR_MGMT

# add the br-mgmt's default gw into routing table.
sed -i "/flock/a\\route add default gw $DEFAULT_GW_BR_MGMT" \
       /etc/rc.local

set_NIC
set_hostname $NAME

# setup the /etc/hosts.
setup_hosts $CPU_COUNT
sed -i "/node-372/d" /etc/hosts
sed -i "/node-373/d" /etc/hosts

# setup this in /etc/nova/nova.conf to reach the vnc server.
sed -i "/^vncserver_proxyclient_address/d" /etc/nova/nova.conf
sed -i "/^\[DEFAULT/a\\vncserver_proxyclient_address=$FIXED_IP_BR_MGMT" /etc/nova/nova.conf

# set the proper user for KVM to avoid the following ERROR:
# "Could not access KVM kernel module: Permission denied\nfailed 
# to initialize KVM"
sed -i "s/^#user = \"root\"/user = \"root\"/" /etc/libvirt/qemu.conf
sed -i "s/^#group = \"root\"/group = \"root\"/" /etc/libvirt/qemu.conf
service libvirtd restart

install_ceph_client && setup_nova_conf "vms88"

# reboot vms in order to make above changes taking effect.
rebootVM

# exit safely.
exit 0
