# Azure Data Explorer

> :warning: **experimental**
#### TODOs

- setup Event Hubs for continuous ingestion
  - probably need to get rid of run-id in blob path
- create ARM template to replace az calls
  - also: kusto calls deprecated
- create a single graph with
  - latency + ping together
- annotate the graphs with title, axis, etc.


## Setup

````bash
cd vars
cp template.adx.vars.json adx.vars.json
vi adx.vars.json
 # change values
cd ..
````

````bash
./run.create.sh

# follow the instructions for manual setup step
````
### Upload Results
After running tests, upload results into the blob storage:
````bash
./upload.test-results.sh {directory to test results}
````
### Import Results from Blob into Data Explorer

Follow the instructions at the end of the upload script.

### Kusto Timeseries Graphs

#### Ping
````bash
// let min_t = toscalar(ping | summarize min(timestamp));
let min_t = toscalar(todatetime("2020-10-01T08:50:00Z"));
let max_t = toscalar(ping | summarize max(sample_start_timestamp));
ping
| make-series
    ping_rtt_min=avg(metrics_ping_rtt_min_value),
    ping_rtt_avg=avg(metrics_ping_rtt_avg_value),
    ping_rtt_max=avg(metrics_ping_rtt_max_value)
    on sample_start_timestamp in range (min_t, max_t, 1m)
    // by run_id
| render timechart
````

#### Latency


````bash
let min_t = toscalar(latency | summarize min(sample_start_timestamp));
// let min_t = toscalar(todatetime("2020-09-30T14:16:00Z"));
let max_t = toscalar(latency | summarize max(sample_start_timestamp));
latency
| make-series
     lat_rtt_avg=avg(metrics_latency_node_latency_latency_stats_average_latency_for_subs_usec),
     lat_rtt_50=avg(metrics_latency_node_latency_latency_stats_50th_percentile_latency_usec),
     lat_rtt_95=avg(metrics_latency_node_latency_latency_stats_95th_percentile_latency_usec),
     lat_rtt_99=avg(metrics_latency_node_latency_latency_stats_99th_percentile_latency_usec),
     lat_rtt_99_9=avg(metrics_latency_node_latency_latency_stats_99_9th_percentile_latency_usec)
     on sample_start_timestamp in range (min_t, max_t, 1m)
     // by run_id
| render timechart
````

#### VPN
````bash
let min_t = toscalar(vpn | summarize min(sample_start_timestamp));
// let min_t = toscalar(todatetime("2020-09-30T14:16:00Z"));
let max_t = toscalar(vpn | summarize max(sample_start_timestamp));
vpn
| make-series
     vpn_avg_rx_msg_rate_per_sec=avg(metrics_averageRxMsgRate),
     vpn_avg_tx_msg_rate_per_sec=avg(metrics_averageTxMsgRate)
     on sample_start_timestamp in range (min_t, max_t, 1m)
     // by run_id
| render timechart
````
---
The End.