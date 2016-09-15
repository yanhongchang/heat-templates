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

# add bridges		 
function set_bridges()
{
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

  # p_ff798dba-0:
  touch ${NIC_DIR}/ifcfg-p_ff798dba-0
  cat > ${NIC_DIR}/ifcfg-p_ff798dba-0 <<EOF
auto p_ff798dba-0
allow-br-floating p_ff798dba-0
iface p_ff798dba-0 inet manual
mtu 6500
ovs_type OVSIntPort
ovs_bridge br-floating
EOF

  # br-floating
  touch ${NIC_DIR}/ifcfg-br-floating
  cat > ${NIC_DIR}/ifcfg-br-floating <<EOF
auto br-floating
allow-ovs br-floating
iface br-floating inet manual
ovs_ports p_ff798dba-0
ovs_type OVSBridge
EOF

}

# Begin setup NICs		 
function set_NIC()
{
  # set "dhcp" to "manual" for eth0~eth4.
  for i in `ls ${NIC_DIR}/*eth*`
  do
    sed -i "s/dhcp/manual/" $i
  done  
}

# setup mac address for b_public in haproxy ns
# usage: set_mac_addr_4_HA haproxy b_public mac_address
#        set_mac_addr_4_HA vrouter b_vrouter mac_address
function set_mac_addr_4_NS()
{
  cp /home/setup_mac_addresss_4_b_public.sh /home/setup_mac_addr_4_${2}.sh

  sed -i "s/haproxy/$1/g" /home/setup_mac_addr_4_${2}.sh  
  sed -i "s/b_public/$2/g" /home/setup_mac_addr_4_${2}.sh  
  sed -i "/hw ether/d" /home/setup_mac_addr_4_${2}.sh
  sed -i "/# by floating ip/a\\ip netns exec $1 ifconfig $2 hw ether $3" \
         /home/setup_mac_addr_4_${2}.sh

  if [ $2 == "b_vrouter" ]; then
    sed -i "/netmask/d" /home/setup_mac_addr_4_${2}.sh
    sed -i "/hw ether/a\\ip netns exec vrouter ifconfig b_vrouter $4 netmask $5" \
           /home/setup_mac_addr_4_${2}.sh
  fi

  sed -i "/setup_mac_addr_4_${2}/d" /etc/rc.local
  cat >> /etc/rc.local <<EOF
sh "/home/setup_mac_addr_4_${2}.sh" &
EOF
}

# reboot the VM to setup the NICs.
function rebootVM()
{
  while true
  do
    echo "Please wait for the NICs going ready..."

    if [ -f "${NIC_DIR}/ifcfg-br-ex" ]; then
      if [ ! -f "/home/lock.file" ]; then
        touch /home/lock.file
        reboot
      fi

      break

    fi
  done

  echo "Successfully setup the NICs..." >> /home/lock.file
  echo "DO NOT DELETE THIS FILE" >> /home/lock.file
}

function install_ceph_client()
{
  sed -i "s/10.20.0.9/$CEPH_FIXED_IP/g" /etc/ceph/ceph.conf
  python /home/sdx@10.100.218.73/install-cephclient.py controller  
}

function create_osd_pool()
{
  ceph osd pool create $1 $2
}

function setup_glance_conf()
{
  sed -i "s/images10/$1/g" /etc/glance/glance-api.conf
}

function setup_cinder_conf()
{
  sed -i "s/volumes10/$1/g" /etc/cinder/cinder.conf
  sed -i "s/backups10/$2/g" /etc/cinder/cinder.conf
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
192.168.121.$i    host-${i}.domain.tld     host-$i
EOF
  
  let i=i+1
  done
}

########################################################
#		        MAIN			       #
########################################################

set_bridges
set_NIC
setup_hosts $CPU_COUNT

# set mac address for HA and vrouter.
set_mac_addr_4_NS "haproxy" "b_public" "62:41:20:cd:a7:2b"
set_mac_addr_4_NS "haproxy" "b_management" "96:4c:66:b3:4a:a9"
set_mac_addr_4_NS "vrouter" "b_vrouter" "9e:38:59:e7:58:be" $DEFAULT_GATEWAY $NET_MASK
set_mac_addr_4_NS "vrouter" "b_vrouter_pub" "8a:b1:73:45:2c:83"

# update /etc/ceph/ceph.conf and install ceph client.
install_ceph_client

create_osd_pool "vms88" "128"
create_osd_pool "volumes88" "128"
create_osd_pool "images88" "128"
create_osd_pool "backups88" "128"

setup_glance_conf "images88"
setup_cinder_conf "volumes88" "backups88"

# reboot vms to make changes taking effective.
rebootVM

# exit safely.
exit 0


