Usage:
  run the following command(or just run the ./lenovo.cmd) 
   heat stack-create -e lenovo.env.yaml -f lenovo.host.yaml stack_name

Notes:
1. the external network is pre-created.

2. all internal networks are post-created automatically.

3. it is better to provide the fixed IP for ceph in the range 10.20.0.4~10.20.0.9 if it is needed.

