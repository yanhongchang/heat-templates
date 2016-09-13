Usage:
  1. run the following command(or just run the ./lenovo.cmd) 
   	heat stack-create -e lenovo.env.yaml -f lenovo.hot.yaml stack_name
  2. run the following command to update the stack ^M
	heat stack-create -e lenovo.env.yaml -f lenovo.hot.yaml stack_name ^M

Notes:
1. the external network is pre-created.

2. all internal networks are post-created automatically.

3. it is better to provide the fixed IP for ceph in the range 10.20.0.4~10.20.0.9 if it is needed.

4. the following ips are in use for VIPs: ^M
    192.168.121.1 is for dhcp server;^M
    192.168.121.2 is for b_management in haproxy; ^M
    192.168.121.3 is for b-mgmt on controller. ^M
    192.168.100.60 is b_public in haroxy. ^M
    192.168.100.61 is b_vrouter_pub in vrouter. ^M
