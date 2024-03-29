#!/usr/bin/env bash
# ---------------------------------------------------------------------------------------------
# MIT License
# Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com)
# ---------------------------------------------------------------------------------------------

trap "" SIGKILL

echo;
echo "##############################################################################################################"
echo "# Running Monitor Latency ..."
echo

##############################################################################################################################
# Prepare
scriptDir=$(cd $(dirname "$0") && pwd);
scriptName=$(basename $(test -L "$0" && readlink "$0" || echo "$0"));
projectHome=${scriptDir%/uc-non-persistent/*}
usecaseHome=$projectHome/uc-non-persistent
source $projectHome/.lib/functions.sh

############################################################################################################################
# Arguments & Environment Variables

  if [ -z "$UC_NON_PERSISTENT_INFRASTRUCTURE" ]; then echo ">>> ERROR: missing env var: UC_NON_PERSISTENT_INFRASTRUCTURE"; exit 1; fi
  if [ -z "$RUN_SPEC_FILE" ]; then echo ">>> ERROR: missing env var: RUN_SPEC_FILE"; exit 1; fi
  if [ -z "$SHARED_SETUP_DIR" ]; then echo ">>> ERROR: missing env var: SHARED_SETUP_DIR"; exit 1; fi
  if [ -z "$RUN_LOG_FILE_BASE" ]; then echo ">>> ERROR: missing env var:RUN_LOG_FILE_BASE"; exit 1; fi
  if [ -z "$RUN_ID" ]; then echo ">>> ERROR: missing env var:RUN_ID"; exit 1; fi
  if [ -z "$RUN_START_TS_EPOCH_SECS" ]; then echo ">>> ERROR: missing env var:RUN_START_TS_EPOCH_SECS"; exit 1; fi

############################################################################################################################
# Settings

    export ANSIBLE_LOG_PATH="$RUN_LOG_FILE_BASE.$scriptName.ansible.log"
    export ANSIBLE_DEBUG=False
    export ANSIBLE_HOST_KEY_CHECKING=False

##############################################################################################################################
# Prepare
cloudProvider=${UC_NON_PERSISTENT_INFRASTRUCTURE%%.*}
resultDirBase="$usecaseHome/test-results/stats/$UC_NON_PERSISTENT_INFRASTRUCTURE"
resultDir="$resultDirBase/run.current"
statsName="latency_stats"
rm -f "$resultDir/$statsName".*.json

##############################################################################################################################
# Run

  inventoryFile=$(assertFile "$SHARED_SETUP_DIR/$UC_NON_PERSISTENT_INFRASTRUCTURE.inventory.json") || exit
  playbook="$scriptDir/playbooks/sdkperf.latency.playbook.yml"
  privateKeyFile=$(assertFile "$usecaseHome/keys/"$cloudProvider"_key") || exit
  hosts="sdkperf_latency"

  ansible-playbook \
                  --fork 1 \
                  -i $inventoryFile \
                  --private-key $privateKeyFile \
                  $playbook \
                  --extra-vars "HOSTS=$hosts" \
                  --extra-vars "RESULT_DIR=$resultDir" \
                  --extra-vars "RUN_ID=$RUN_ID" \
                  --extra-vars "RUN_START_TS_EPOCH_SECS=$RUN_START_TS_EPOCH_SECS" \
                  --extra-vars "STATS_NAME=$statsName" \
                  --extra-vars "RUN_SPEC_FILE=$RUN_SPEC_FILE" \
                  --extra-vars "RUN_LOCALLY=False"

  code=$?; if [[ $code != 0 ]]; then echo ">>> ERROR - $code - playbook exit: $scriptName"; echo; exit 1; fi


###
# The End.
