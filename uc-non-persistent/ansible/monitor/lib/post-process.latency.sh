#!/bin/bash
# ---------------------------------------------------------------------------------------------
# MIT License
# Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com)
# ---------------------------------------------------------------------------------------------

# usage:
# cat latency.log | prost-process.latency.sh latency-template.json {timestamp-string} {sdkperf_command}
# stdout: the json
# stderr: any errors

if [ ! -p /dev/stdin ]; then echo "no latency log input received" >>/dev/stderr; exit 1; fi
if [[ ! -f "$1" ]]; then echo "template file: '$1' not found." >>/dev/stderr; exit 1; fi
if [ -z "$2" ]; then echo "no timestamp string received" >>/dev/stderr; exit 1; fi
if [ -z "$3" ]; then echo "no sdkperf_command received" >>/dev/stderr; exit 1; fi
export timestamp=$2
export sdkperf_command=$3

latencyJson=$(cat $1 | jq -r .)
latencyJson=$( echo $latencyJson | jq -r '.timestamp=env.timestamp' )
latencyJson=$( echo $latencyJson | jq -r '.meta.sdkperf_command=env.sdkperf_command' )

# read input line by line
lineCount=0
statsString=""
stats_start_match=0
while IFS= read line; do
  export lineCount
  export line
  # record the original line
  latencyJson=$( echo $latencyJson | jq -r '.meta.log_file[env.lineCount|tonumber]=env.line' )
  # test for start of json
  if [ $stats_start_match -eq 0 ]; then
    stats_start_match=$(expr "$line" : "{")
  fi
  if [ $stats_start_match -gt 0 ]; then
    # add line to stats string
    statsString+=$line
  fi
  ((lineCount++))
done

# test that it is correct JSON
export statsJson=$(echo $statsString | jq -r)
  if [ -z "$statsJson" ]; then echo "jq parse error of stats=$statsString" >>/dev/stderr; exit 1; fi
latencyJson=$( echo $latencyJson | jq -r '.metrics=(env.statsJson | fromjson)')

echo $latencyJson

###
# The End.
