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
  for i in `ls *eth*`; do
    sed -i "s/dhcp/manual/" $i
  done  
}


# setup mac address for b_public in haproxy ns
function set_mac_addr_4_b_pub()
{
  # add the script into rc.local in case if will run every booting.
  sed -i "/setup_mac_addr_4_b_public/d" /etc/rc.local
  cat >> /etc/rc.local <<EOF 
sh "/home/setup_mac_addr_4_b_public.sh" &
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

  echo "Successfully setup the NICs..."
}

########################################################
#		        MAIN			       #
########################################################

# set mac address for b_public. It should be the same 
# as is shown in allowed_address_pairs, which can be
# displayed by "neutron port-show port_id".
touch /home/setup_mac_addr_4_b_public.sh
chmod 777 /home/setup_mac_addr_4_b_public.sh
cat > /home/setup_mac_addr_4_b_public.sh <<EOF
#!/bin/bash

# check if the b_public is up before setup the mac address for it.

is_b_pub_ready=1
until [ is_b_pub_ready -ne 1 ]
do
  ip netns exec haproxy ifconfig | grep b_public
  is_b_pub_ready=$?
  sleep 1
done

# setup the mac address for b_public in case we can ping it by the 
# floating ip.
ip netns exec haproxy ifconfig b_public hw ether 62:41:20:cd:a7:2b
EOF

set_bridges
set_NIC
set_mac_addr_4_b_pub
rebootVM

# exit safely.
exit 0


