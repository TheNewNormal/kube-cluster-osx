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

### Start VMs
cd ~/kube-cluster
#
echo " "
echo "Starting k8smaster-01 VM ..."
echo -e "$my_password\n" | sudo -Sv > /dev/null 2>&1
#
sudo "${res_folder}"/bin/corectl load settings/k8smaster-01.toml 2>&1 | tee ~/kube-cluster/logs/master_vm_reload.log
CHECK_VM_STATUS=$(cat ~/kube-cluster/logs/master_vm_reload.log | grep "started")
#
if [[ "$CHECK_VM_STATUS" == "" ]]; then
    echo " "
    echo "Master VM has not booted, please check '~/kube-cluster/logs/master_vm_reload.log' and report the problem !!! "
    echo " "
    pause 'Press [Enter] key to continue...'
    exit 0
else
    echo "Master VM successfully started !!!" >> ~/kube-cluster/logs/master_vm_reload.log
fi
# check id /Users/homefolder is mounted, if not mount it
"${res_folder}"/bin/corectl ssh k8smaster-01 'source /etc/environment; if df -h | grep ${HOMEDIR}; then echo 0; else sudo systemctl restart ${HOMEDIR}; fi' > /dev/null 2>&1
echo " "
# save master VM's IP
"${res_folder}"/bin/corectl q -i k8smaster-01 | tr -d "\n" > ~/kube-cluster/.env/master_ip_address
# get master VM's IP
master_vm_ip=$("${res_folder}"/bin/corectl q -i k8smaster-01)
#
#
echo " "
echo "Starting k8snode-01 VM ..."
echo -e "$my_password\n" | sudo -Sv > /dev/null 2>&1
#
sudo "${res_folder}"/bin/corectl load settings/k8snode-01.toml 2>&1 | tee ~/kube-cluster/logs/node1_vm_reload.log
CHECK_VM_STATUS=$(cat ~/kube-cluster/logs/node1_vm_reload.log | grep "started")
#
if [[ "$CHECK_VM_STATUS" == "" ]]; then
    echo " "
    echo "Node1 VM has not booted, please check '~/kube-cluster/logs/node1_vm_reload.log' and report the problem !!! "
    echo " "
    pause 'Press [Enter] key to continue...'
    exit 0
else
    echo "Node1 VM successfully started !!!" >> ~/kube-cluster/logs/node1_vm_reload.log
fi
# check id /Users/homefolder is mounted, if not mount it
"${res_folder}"/bin/corectl ssh k8snode-01 'source /etc/environment; if df -h | grep ${HOMEDIR}; then echo 0; else sudo systemctl restart ${HOMEDIR}; fi' > /dev/null 2>&1
echo " "
# save node1 VM's IP
"${res_folder}"/bin/corectl q -i k8snode-01 | tr -d "\n" > ~/kube-cluster/.env/node1_ip_address
# get node1 VM's IP
node1_vm_ip=$("${res_folder}"/bin/corectl q -i k8snode-01)
#
#
echo " "
echo "Starting k8snode-02 VM ..."
echo -e "$my_password\n" | sudo -Sv > /dev/null 2>&1
#
sudo "${res_folder}"/bin/corectl load settings/k8snode-02.toml 2>&1 | tee ~/kube-cluster/logs/node2_vm_reload.log
CHECK_VM_STATUS=$(cat ~/kube-cluster/logs/node2_vm_reload.log | grep "started")
#
if [[ "$CHECK_VM_STATUS" == "" ]]; then
    echo " "
    echo "Node2 VM has not booted, please check '~/kube-cluster/logs/node2_vm_reload.log' and report the problem !!! "
    echo " "
    pause 'Press [Enter] key to continue...'
    exit 0
else
    echo "Node2 VM successfully started !!!" >> ~/kube-cluster/logs/node2_vm_reload.log
fi
# check id /Users/homefolder is mounted, if not mount it
"${res_folder}"/bin/corectl ssh k8snode-02 'source /etc/environment; if df -h | grep ${HOMEDIR}; then echo 0; else sudo systemctl restart ${HOMEDIR}; fi' > /dev/null 2>&1
echo " "
# save node2 VM's IP
"${res_folder}"/bin/corectl q -i k8snode-02 | tr -d "\n" > ~/kube-cluster/.env/node2_ip_address
# get node2 VM's IP
node2_vm_ip=$("${res_folder}"/bin/corectl q -i k8snode-02)
###

# set fleetctl endpoint
export FLEETCTL_ENDPOINT=http://$master_vm_ip:2379
export FLEETCTL_DRIVER=etcd
export FLEETCTL_STRICT_HOST_KEY_CHECKING=false

# wait till VM is ready
echo "Waiting for VM to be ready..."
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
