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

  if [ -z "$TEST_SPEC_FILE" ]; then echo ">>> ERROR: missing env var:TEST_SPEC_FILE"; exit 1; fi
    x=$(assertFile "$TEST_SPEC_FILE") || exit

  if [ -z "$TEST_SPEC_DIR" ]; then echo ">>> ERROR: missing env var:TEST_SPEC_DIR"; exit 1; fi
  if [ -z "$SHARED_SETUP_DIR" ]; then echo ">>> ERROR: missing env var:SHARED_SETUP_DIR"; exit 1; fi

############################################################################################################################
# Generate Run Specs

  playbook="$scriptDir/playbooks/generate.test-spec.playbook.yml"
  ansible-playbook \
                  $playbook \
                  --extra-vars "TEST_SPEC_FILE=$TEST_SPEC_FILE" \
                  --extra-vars "TEST_SPEC_DIR=$TEST_SPEC_DIR" \
                  --extra-vars "SHARED_SETUP_DIR=$SHARED_SETUP_DIR"

  code=$?; if [[ $code != 0 ]]; then echo ">>> ERROR - $code - playbook exit: $scriptName"; echo; exit 1; fi

###
# The End.