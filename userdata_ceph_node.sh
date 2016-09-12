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
  /usr/sbin/mkfs.f2fs /home/f2fs.conf
  chmod 777 /home/mount.sh
  sh /home/mount.sh
}

# format the disk.
function format_disk()
{
  /sbin/mkcephfs -a -c /etc/ceph/ceph.conf
}

# start ceph.
function start_ceph()
{
  /etc/init.d/ceph -a -c /etc/ceph/ceph.conf start
}

####################################################
# 		        MAIN			   #
####################################################

# 1. get the NIC ip and set the ceph.conf.
IP_ADDR=`get_ip "eth0"`
sed -i "s/192.168.100.85/$IP_ADDR/g" /etc/ceph/ceph.conf

# 2. clear data.
rm -rf /Ceph/Data/Osd/osd-0/*
rm -rf /Ceph/Data/Mon/*

# 3. mount the disk.
# 4. format.
# 5. start ceph
mount_disk && format_disk && start_ceph

touch /home/lock.file

