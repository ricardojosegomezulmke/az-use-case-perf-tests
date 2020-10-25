#!/usr/bin/env bash
# ---------------------------------------------------------------------------------------------
# MIT License
# Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com)
# ---------------------------------------------------------------------------------------------

##############################################################################################################################
# Prepare
scriptDir=$(cd $(dirname "$0") && pwd);
scriptName=$(basename $(test -L "$0" && readlink "$0" || echo "$0"));
projectHome=${scriptDir%/uc-non-persistent/*}
usecaseHome=$projectHome/uc-non-persistent
source $projectHome/.lib/functions.sh

############################################################################################################################
# Environment Variables

  if [ -z "$INFRASTRUCTURE_IDS" ]; then echo ">>> ERROR: - $scriptName - missing env var:INFRASTRUCTURE_IDS"; exit 1; fi
  if [ -z "$LOG_DIR" ]; then echo ">>> ERROR: - $scriptName - missing env var:LOG_DIR"; exit 1; fi
  if [ -z "$TF_VARIABLES_DIR" ]; then echo ">>> ERROR: - $scriptName - missing env var:TF_VARIABLES_DIR"; exit 1; fi

  # if [ -z "$TERRAFORM_DIR" ]; then echo ">>> ERROR: - $scriptName - missing env var:TERRAFORM_DIR"; exit 1; fi
  # if [ -z "$TERRAFORM_VAR_FILE" ]; then echo ">>> ERROR: - $scriptName - missing env var:VARIABLES_FILE"; exit 1; fi
  # if [ -z "$TERRAFORM_STATE_FILE" ]; then echo ">>> ERROR: - $scriptName - missing env var:TERRAFORM_STATE_FILE"; exit 1; fi
  # if [ -z "$TF_LOG_PATH" ]; then echo ">>> ERROR: - $scriptName - missing env var:TF_LOG_PATH"; exit 1; fi

##############################################################################################################################
# Call scripts

  callScript=_run.destroy.sh

  for infrastructureId in ${INFRASTRUCTURE_IDS[@]}; do
    idArr=(${infrastructureId//./ })
    cloudProvider=${idArr[0]}
    infraConfig=${idArr[1]}
    echo ">>> Destroy $infraConfig on $cloudProvider ..."

      export TERRAFORM_DIR="$scriptDir/$cloudProvider"
      export TERRAFORM_VAR_FILE="$TF_VARIABLES_DIR/$infrastructureId.tfvars.json"
      export TERRAFORM_STATE_FILE="tfstate/$infrastructureId.tfstate"

      export TF_LOG_PATH="$LOG_DIR/$infrastructureId.$callScript.terraform.log"

      nohup $scriptDir/$callScript > $LOG_DIR/$infrastructureId.$callScript.out 2>&1 &
      scriptPids+=" $!"

  done

##############################################################################################################################
# wait for all jobs to finish

  wait ${scriptPids[*]}

##############################################################################################################################
# Check for errors

  filePattern="$LOG_DIR/*.$callScript.out"
  errors=$(grep -n -e "ERROR" $filePattern )

  if [ -z "$errors" ]; then
    echo ">>> FINISHED:SUCCESS - $scriptName";
    touch "$LOG_DIR/$callScript.SUCCESS.out"
  else
    echo ">>> FINISHED:FAILED";

    while IFS= read line; do
      echo $line >> "$LOG_DIR/$callScript.ERROR.out"
    done < <(printf '%s\n' "$errors")

    exit 1
  fi

###
# The End.