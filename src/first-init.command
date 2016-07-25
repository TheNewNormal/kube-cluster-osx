#!/bin/bash

#  first-init.command
#

#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-cluster/.env/resouces_path)

# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-cluster/bin:$PATH

echo " "
echo "Setting up Kubernetes Cluster for macOS"

# add ssh key to *.toml files
sshkey

# add ssh key to Keychain
if ! ssh-add -l | grep -q ssh/id_rsa; then
    ssh-add -K ~/.ssh/id_rsa &>/dev/null
fi

# Set release channel
release_channel

# set Nodes RAM
change_nodes_ram

# create Data disk
create_data_disk

# start cluster VMs
start_vms

# check internet from VMs
echo " "
echo "Checking internet availablity on VMs..."
check_internet_from_vm

# install k8s files on to VMs
install_k8s_files
echo " "
#

# download latest version of fleetctl and helmc clients
download_osx_clients
#

# set etcd endpoint
export ETCDCTL_PEERS=http://$master_vm_ip:2379

# wait till etcd service is ready
echo " "
echo "--------"
echo "Waiting for etcd service to be ready on master VM..."
spin='-\|/'
i=1
until curl -o /dev/null http://$master_vm_ip:2379 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
echo "..."
echo " "

# set fleetctl endpoint and install fleet units
export FLEETCTL_TUNNEL=
export FLEETCTL_ENDPOINT=http://$master_vm_ip:2379
export FLEETCTL_DRIVER=etcd
export FLEETCTL_STRICT_HOST_KEY_CHECKING=false
echo " "
echo "fleetctl list-machines:"
fleetctl list-machines
echo " "
#
deploy_fleet_units
#

sleep 3

# generate kubeconfig file
echo " "
echo "Generating kubeconfig file ..."
"${res_folder}"/bin/gen_kubeconfig $master_vm_ip
#

# set kubernetes master
export KUBERNETES_MASTER=http://$master_vm_ip:8080
#
echo "  "
echo "Waiting for Kubernetes cluster to be ready. This can take a few minutes..."
spin='-\|/'
i=1
until curl -o /dev/null http://$master_vm_ip:8080 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
i=1
until ~/kube-cluster/bin/kubectl version | grep 'Server Version' >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\b${spin:i++%${#sp}:1}"; sleep .1; done
echo "..."
echo " "
echo "Waiting for Kubernetes nodes to be ready. This can take a bit..."
i=1
until ~/kube-cluster/bin/kubectl get nodes | grep -w "k8snode-01" | grep -w "Ready" >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
i=1
until ~/kube-cluster/bin/kubectl get nodes | grep -w "k8snode-02" | grep -w "Ready" >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
echo "..."
echo " "
#
install_k8s_add_ons
#
# attach label to the nodes
~/kube-cluster/bin/kubectl label nodes k8snode-01 node=worker1
~/kube-cluster/bin/kubectl label nodes k8snode-02 node=worker2
#
# remove unfinished_setup file
rm -f ~/kube-cluster/logs/unfinished_setup > /dev/null 2>&1
#
echo "  "
echo "fleetctl list-machines:"
fleetctl list-machines
echo " "
echo "fleetctl list-units:"
fleetctl list-units
echo " "
echo "kubectl get nodes:"
~/kube-cluster/bin/kubectl get nodes
echo " "
#
echo "kubectl cluster-info:"
~/kube-cluster/bin/kubectl cluster-info
echo " "
#
echo "Installation has finished, Kube Cluster VMs are up and running !!!"
echo " "
echo "Assigned static IP for master VM: $master_vm_ip"
echo "Assigned static IP for node1 VM: $node1_vm_ip"
echo "Assigned static IP for node2 VM: $node2_vm_ip"
echo " "
echo "You can control this App via status bar icon... "
echo " "

echo "Also you can install Deis Workflow PaaS (https://deis.com) with 'install_deis' command ..."
echo " "

cd ~/kube-cluster

# open user's preferred shell
if [[ ! -z "$SHELL" ]]; then
    $SHELL
else
    /bin/bash
fi




