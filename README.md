# heat-templates
using heat to deploy the openstack dev environment

image: it is get from the existing controller and compute nodes.

fuel: the origin openstack env is create with fuel.


useage:

1.Create a new stack

./lenovo.cmd

2.Updata an existing stack

heat stack-update -f lenovo.hot.yaml -e lenovo.env.yaml stack-name


NOTES:

1. we can add the configuration commands in userdata_compute_node.sh
   and userdata_controller_node.sh to setup your controller node and 
   compute node accordingly.



