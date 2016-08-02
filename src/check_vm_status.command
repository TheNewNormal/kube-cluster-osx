#!/bin/bash

#  check VM status
#

# get App's Resources folder
res_folder=$(cat ~/kube-cluster/.env/resouces_path)

# check VM status
status=$(~/bin/corectl ps 2>&1 | grep "[k]8smaster-01")

if [ "$status" = "" ]; then
    echo -n "VMs are stopped"
else
    echo -n "VMs are running"
fi
