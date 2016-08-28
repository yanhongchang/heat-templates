# heat-templates
using heat to deploy the openstack dev environment

image: it is get from the existing controller and compute nodes.

fuel: the origin openstack env is create with fuel.


useage:

1. Create a new stack

./lenovo.cmd

2. Updata an existing stack

heat stack-update -f lenovo.hot.yaml -e lenovo.env.yaml stack-name


