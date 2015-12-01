#!/bin/bash

#  ssh.command
# run commands on VM via ssh
#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-cluster/.env/resouces_path)

# get VM IP
#vm_ip=$( ~/kube-cluster/mac2ip.sh $(cat ~/kube-cluster/.env/mac_address))
vm_ip=$(cat ~/kube-cluster/.env/ip_address)

# pass some arguments via $1 $2 ...
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no core@$master_vm_ip $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12}
