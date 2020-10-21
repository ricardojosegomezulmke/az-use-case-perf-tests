#!/usr/bin/env bash
# ---------------------------------------------------------------------------------------------
# MIT License
# Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com)
# ---------------------------------------------------------------------------------------------

scriptDir=$(cd $(dirname "$0") && pwd);

export TEST_SPEC_FILE="$scriptDir/specs/.test/1_test.test.spec.yml"

export ANSIBLE_VERBOSITY=3

# nohup ./_run.sh > ./_run.sh.log 2>&1 &
nohup ./_run.sh > nohup.out 2>&1 &

###
# The End.
