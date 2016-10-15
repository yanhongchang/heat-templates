#!/bin/bash

## Author: 	Jeffrey Guan
## Name: 	userdata_ceph_node.sh
## Date: 	2016-09-01
## Note: 	userdata file for ceph node.
## Version: 	v1.0

# get the NIC's ip.
function get_ip()
{
  ifconfig $1 | grep "inet addr" |	\
  cut -d ":" -f 2 | cut -d " " -f 1
}

# mount the disk.
function mount_disk()
{
  # check if the /dev/vda4 is mounted.
  mount | grep "/dev/vda4"
  check_mount=$?

  # umount /dev/vda4 if it is mounted.
  if [ 0 -eq ${check_mount} ]; then
    umount /dev/vda4
  fi

  /usr/sbin/mkfs.f2fs /home/f2fs.conf

  chmod 777 /home/mount.sh
  sh /home/mount.sh
}

# create ceph fs.
function create_cephfs()
{
  if [ ! -e /home/create_cephfs.sh ]; then
    touch /home/create_cephfs.sh
  fi

  # delete the known_hosts, otherwise cannot ssh to $IP_ADDR.
  if [ -e /root/.ssh/known_hosts ]; then
    rm /root/.ssh/known_hosts
  fi

# to erease the interaction.
  cat > /home/create_cephfs.sh <<EOF
#!/usr/bin/expect

# create the ceph fs.
spawn /sbin/mkcephfs -a -c /etc/ceph/ceph.conf
expect {
  "(yes/no)" { send "yes\r"; exp_continue }
  eof
}
EOF

  chmod 777 /home/create_cephfs.sh
  /home/create_cephfs.sh
}

# start ceph.
function start_ceph()
{
  if [ ! -e /home/start_ceph.sh ]; then
    touch /home/start_ceph.sh
  fi

  # delete the known_hosts, otherwise cannot ssh to $IP_ADDR.
  if [ -e /root/.ssh/known_hosts ]; then
    rm /root/.ssh/known_hosts
  fi

# to erease the interaction.
  cat > /home/start_ceph.sh <<EOF
#!/usr/bin/expect

# start ceph
spawn /etc/init.d/ceph -a -c /etc/ceph/ceph.conf start
expect {
  "(yes/no)" { send "yes\r"; exp_continue }
  eof
}
EOF

  chmod 777 /home/start_ceph.sh
  /home/start_ceph.sh
}

####################################################
# 		        MAIN			   #
####################################################

# set the script will not go timeout.
set timeout -1

# 1. get the NIC ip and set the ceph.conf.
IP_ADDR=`get_ip "eth0"`
sed -i "s/10.20.0.9/$IP_ADDR/g" /etc/ceph/ceph.conf

# 2. clear data.
rm -rf /Ceph/Data/Osd/osd-0/*
rm -rf /Ceph/Data/Mon/*

# delete the known_hosts, otherwise cannot ssh to $IP_ADDR.
if [ -e /root/.ssh/known_hosts ]; then
  rm /root/.ssh/known_hosts
fi

# 3. mount the disk.
# 4. format.
# 5. start ceph.
mount_disk && create_cephfs && start_ceph

# just check if the cloud-init is workable.
touch /home/lock.file

