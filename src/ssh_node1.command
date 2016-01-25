#!/bin/bash

#  ssh_node1.command
# run commands on VM via ssh
#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-cluster/.env/resouces_path)

# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-cluster/bin:$PATH

# ssh into VM
"${res_folder}"/bin/corectl ssh k8snode-01
