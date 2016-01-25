#!/bin/bash

#  kill_VMs.command

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

clean_up_after_vm

