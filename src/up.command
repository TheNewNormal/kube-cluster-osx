#!/bin/bash

# up.command
#

#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# check if offline setting is present in setting files
check_iso_offline_setting

# check corectld server
check_corectld_server

# get App's Resources folder
res_folder=$(cat ~/kube-cluster/.env/resouces_path)

# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-cluster/bin:$PATH

# check if iTerm.app exists
App="/Applications/iTerm.app"
if [ ! -d "$App" ]
then
    unzip "${res_folder}"/files/iTerm2.zip -d /Applications/
fi

# create logs dir
mkdir ~/kube-cluster/logs > /dev/null 2>&1

# copy bin files to ~/kube-cluster/bin
rsync -r --verbose --exclude 'helmc' "${res_folder}"/bin/* ~/kube-cluster/bin/ > /dev/null 2>&1
rm -f ~/kube-cluster/bin/gen_kubeconfig
chmod 755 ~/kube-cluster/bin/*

# add ssh key to Keychain
if ! ssh-add -l | grep -q ssh/id_rsa; then
    ssh-add -K ~/.ssh/id_rsa &>/dev/null
fi
#

# set variable to 0
new_vm=0

### run some checks
# check if master's data disk exists, if not create it
if [ ! -f $HOME/kube-cluster/master-data.img ]; then
    echo " "
    echo "Kube-Cluster data disks do not exist, they will be created now ..."
    create_data_disk
    new_vm=1
fi
# check if '~/kube-cluster/logs/unfinished_setup' file exists
if [ -f "$HOME"/kube-cluster/logs/unfinished_setup ]; then
    # found it, so installation will continue
    new_vm=1
fi
#
###

# start cluster VMs
start_vms

# get master VM's IP
master_vm_ip=$(~/bin/corectl q -i k8smaster-01)


# if the new setup check for internet connection from the master
if [[ "${new_vm}" == "1" ]]
then
    echo " "
    echo "Checking internet availablity on master VM..."
    check_internet_from_vm
fi
#

# Set the shell environment variables
# set etcd endpoint
export ETCDCTL_PEERS=http://$master_vm_ip:2379
# wait till etcd is ready
echo " "
echo "Waiting for etcd service to be ready on k8smaster-01 VM..."
spin='-\|/'
i=1
until curl -o /dev/null http://$master_vm_ip:2379 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
echo "..."
echo " "
#

# set fleetctl endpoint
export FLEETCTL_TUNNEL=
export FLEETCTL_ENDPOINT=http://$master_vm_ip:2379
export FLEETCTL_DRIVER=etcd
export FLEETCTL_STRICT_HOST_KEY_CHECKING=false
#
sleep 3

#
echo "fleetctl list-machines:"
fleetctl list-machines
#

#
if [[ "${new_vm}" == "1" ]]
then
    # copy k8s files to VMS
    install_k8s_files
    #
    echo "  "
    deploy_fleet_units
fi
#

# generate kubeconfig file
if [ ! -f $HOME/kube-cluster/kube/kubeconfig ]; then
    echo Generating kubeconfig file ...
    "${res_folder}"/bin/gen_kubeconfig $master_vm_ip
    echo " "
fi
#

echo " "
# set kubernetes master
export KUBERNETES_MASTER=http://$master_vm_ip:8080
echo "Waiting for Kubernetes cluster to be ready. This can take a few minutes..."
spin='-\|/'
i=1
until curl -o /dev/null -sIf http://$master_vm_ip:8080 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
echo "..."
echo " "
echo "Waiting for Kubernetes nodes to be ready. This can take a bit..."
i=1
until ~/kube-cluster/bin/kubectl get nodes | grep -w "k8snode-01" | grep -w "Ready" >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
i=1
until ~/kube-cluster/bin/kubectl get nodes | grep -w "k8snode-02" | grep -w "Ready" >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
#
echo "..."
echo " "

if [[ "${new_vm}" == "1" ]]
then
    # attach label to the nodes
    ~/kube-cluster/bin/kubectl label nodes k8snode-01 node=worker1
    ~/kube-cluster/bin/kubectl label nodes k8snode-02 node=worker2
    # copy add-ons files
    cp "${res_folder}"/k8s/add-ons/*.yaml ~/kube-cluster/kubernetes
    install_k8s_add_ons
    #
    # remove unfinished_setup file
    rm -f ~/kube-cluster/logs/unfinished_setup > /dev/null 2>&1
fi
#
echo "kubectl get nodes:"
~/kube-cluster/bin/kubectl get nodes
echo " "
#

cd ~/kube-cluster/kubernetes

# open user's preferred shell
if [[ ! -z "$SHELL" ]]; then
    $SHELL
else
    /bin/bash
fi
