# Load


TODO: Rewrite

## Configure
````bash
cd ../../vars
vi sdkperf.vars.yml
# customize the following:
client_connection_count: 1 # 1 || 10 || 100 || 1000 || etc...
msg_payload_size_bytes: 100 # 100 || 1000 || 10000 || etc...
# 0=max
msg_rate_per_second: 200000
````

#### Start Load
````bash
export UC_NON_PERSISTENT_INFRASTRUCTURE={cloud-provider}.{infrastructure-id}
# for example:
export UC_NON_PERSISTENT_INFRASTRUCTURE=azure.infra1-standalone
./start.load.sh
````
Or, pass the infrastrucure as an argument:
````bash
./start.load.sh azure.infra1-standalone
````
#### Stop Load

````bash
./stop.load.sh {with env var or arg as start.load.sh}
````


---
The End.