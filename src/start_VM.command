#!/bin/bash

# Start VM
#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-cluster/.env/resouces_path)

# Get UUID
UUID=$(cat ~/kube-cluster/custom.conf | grep UUID= | head -1 | cut -f2 -d"=")

# Get password
my_password=$(security find-generic-password -wa kube-cluster-app)

# Get mac address and save it
echo -e "$my_password\n" | sudo -S "${res_folder}"/bin/uuid2mac $UUID > ~/kube-cluster/.env/mac_address

# Get VM's IP and save it to file
"${res_folder}"/bin/get_ip &

# Start webserver
cd ~/kube-cluster/cloud-init
"${res_folder}"/bin/webserver start

# Start VM
#echo "Waiting for VM to boot up... "
cd ~/kube-cluster
export XHYVE=~/kube-cluster/bin/xhyve
"${res_folder}"/bin/coreos-xhyve-run -f custom.conf kube-cluster

# Stop webserver
"${res_folder}"/bin/webserver stop
