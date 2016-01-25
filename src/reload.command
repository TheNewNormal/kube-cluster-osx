#!/bin/bash

#  Reload VM
#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-cluster/.env/resouces_path)

# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-cluster/bin:$PATH

# get password for sudo
my_password=$(security find-generic-password -wa kube-cluster-app)
# reset sudo
sudo -k

### Stop VMs
echo " "
echo "Stopping k8smaster-01 VM ..."
# send halt to VM
echo -e "$my_password\n" | sudo -Sv > /dev/null 2>&1
sudo "${res_folder}"/bin/corectl halt k8smaster-01
#
echo " "
echo "Stopping k8snode-01 VM ..."
# send halt to VM
echo -e "$my_password\n" | sudo -Sv > /dev/null 2>&1
sudo "${res_folder}"/bin/corectl halt k8snode-01
#
echo " "
echo "Stopping k8snode-02 VM ..."
# send halt to VM
echo -e "$my_password\n" | sudo -Sv > /dev/null 2>&1
sudo "${res_folder}"/bin/corectl halt k8snode-02
#
sleep 2

### Start cluster VMs
start_vms

# set fleetctl endpoint
export FLEETCTL_ENDPOINT=http://$master_vm_ip:2379
export FLEETCTL_DRIVER=etcd
export FLEETCTL_STRICT_HOST_KEY_CHECKING=false

# wait till VM is ready
echo "Waiting for k8smaster-01 to be ready..."
spin='-\|/'
i=1
until curl -o /dev/null http://$master_vm_ip:2379 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
echo " "
#

sleep 2

#
echo " "
echo "fleetctl list-machines:"
fleetctl list-machines
echo ""

# deploy fleet units from ~/kube-cluster/fleet
deploy_fleet_units
#

echo "CoreOS VMs have been reloaded !!!"
echo ""
pause 'Press [Enter] key to continue...'
