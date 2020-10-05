#!/bin/bash
# ---------------------------------------------------------------------------------------------
# MIT License
# Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com)
# ---------------------------------------------------------------------------------------------

##############################################################################################################################
# Prepare
scriptDir=$(cd $(dirname "$0") && pwd);
source $scriptDir/.lib/functions.sh
scriptName=$(basename $(test -L "$0" && readlink "$0" || echo "$0"));
projectHome=${scriptDir%/ansible/*}
monitorVarsFile=$(assertFile "$scriptDir/vars/monitor.vars.yml") || exit
pids=""

############################################################################################################################
# Environment Variables

  # is set, doesn't wait for user input
  auto=$2

    if [ -z "$1" ]; then
      if [ -z "$UC_NON_PERSISTENT_INFRASTRUCTURE" ]; then
          echo ">>> missing infrastructure info. pass either as env-var: UC_NON_PERSISTENT_INFRASTRUCTURE or as argument"
          echo "    for example: ./run.bootstrap.sh azure.standalone"
          echo; exit 1
      fi
    else
      export UC_NON_PERSISTENT_INFRASTRUCTURE=$1
    fi


##############################################################################################################################
# Prepare
cloudProvider=${UC_NON_PERSISTENT_INFRASTRUCTURE%%.*}
resultDirBase="$projectHome/test-results/stats/$UC_NON_PERSISTENT_INFRASTRUCTURE"
resultDir="$resultDirBase/run.current"
resultDirLatest="$resultDirBase/run.latest"
# Set for all monitors
export runId=$(date -u +"%Y-%m-%d-%H-%M-%S")
export runStartTsEpochSecs=$(date -u +%s)

totalNumSamplesStr=$(cat $monitorVarsFile | yq '.general.total_num_samples') || exit
totalNumSamples=$((totalNumSamplesStr))
sampleRunTimeSecsStr=$(cat $monitorVarsFile | yq '.general.sample_run_time_secs') || exit
sampleRunTimeSecs=$((sampleRunTimeSecsStr))
testRunMinutes=$((sampleRunTimeSecs/60 * totalNumSamples))

rm -f ./*.log
rm -f $resultDir/*

echo;
echo "##############################################################################################################"
echo "# Starting Monitors"
echo
echo ">>> test run takes approx. $testRunMinutes minutes"
echo ">>> infrastructure   : $UC_NON_PERSISTENT_INFRASTRUCTURE"
echo ">>> cloud provider   : $cloudProvider"
echo ">>> utc start time   : "$(date -u +"%Y-%m-%d %H:%M:%S")
echo ">>> local start time : "$(date +"%Y-%m-%d %H:%M:%S")
echo
if [ -z "$auto" ]; then x=$(wait4Key); fi
echo

# echo "##############################################################################################################"
echo ">>> Start VPN Stats Monitor ..."
  $scriptDir/run.monitor.vpn-stats.sh 2>&1 > $scriptDir/run.monitor.vpn-stats.log &
  vpn_stats_pid=" $!"
  pids+=" $!"

# echo "##############################################################################################################"
echo ">>> Start Latency Stats Monitor ..."
  $scriptDir/run.monitor.latency.sh 2>&1 > $scriptDir/run.monitor.latency.log &
  latency_pid=" $!"
  pids+=" $!"

# echo "##############################################################################################################"
echo ">>> Start Latency Broker Node Stats Monitor ..."
  $scriptDir/run.monitor.brokernode.latency.sh 2>&1 > $scriptDir/run.monitor.brokernode.latency.log &
  brokernode_latency_pid=" $!"
  pids+=" $!"

# echo "##############################################################################################################"
echo ">>> Start Ping Latency Stats Monitor ..."
  $scriptDir/run.monitor.ping.sh 2>&1 > $scriptDir/run.monitor.ping.log &
  ping_pid=" $!"
  pids+=" $!"

# echo "##############################################################################################################"
echo ">>> Waiting for Processes to finish:"
for pid in $pids; do
  ps $pid
done

FAILED=0
for pid in $pids; do
  if wait $pid; then
    echo ">>> SUCCESS: Process $pid"
  else
    echo ">>> FAILED: Process $pid"; FAILED=1
  fi
done

if [ "$FAILED" -gt 0 ]; then
  echo ">>> ERROR: at least one monitor failed. see log files for details.";
  ls -la *.log
  exit 1
fi
##############################################################################################################################
# Post Processing of Results

# copy docker compose deployed template to result dir
cp $projectHome/ansible/docker-image/*.deployed.yml "$resultDir/PubSub.docker-compose.$runId.yml"

##############################################################################################################################
# Move ResultDir to Timestamp
finalResultDir="$resultDirBase/run.$runId"
mv $resultDir $finalResultDir
if [[ $? != 0 ]]; then echo ">>> ERROR moving resultDir=$resultDir."; echo; exit 1; fi
cd $resultDirBase
rm -f $resultDirLatest
ln -s $finalResultDir $resultDirLatest
cd $scriptDir

# echo "##############################################################################################################"
echo
echo ">>> Monitor Results in: $finalResultDir"
echo;echo;

###
# The End.
