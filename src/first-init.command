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
echo "Setting up Kubernetes Cluster for OS X"

# add ssh key to *.toml files
sshkey

# add ssh key to Keychain
if ! ssh-add -l | grep -q ssh/id_rsa; then
    ssh-add -K ~/.ssh/id_rsa &>/dev/null
fi

# save user's password to Keychain
save_password
#

# Set release channel
release_channel

# set Nodes RAM
change_nodes_ram

# create Data disk
create_data_disk

# get password for sudo
my_password=$(security find-generic-password -wa kube-cluster-app)
# reset sudo
sudo -k > /dev/null 2>&1

# start cluster VMs
start_vms

# install k8s files on to VMs
install_k8s_files
#

# download latest version of fleetctl and helm clients
download_osx_clients
#

# run helm for the first time
helm up
# add kube-charts repo
helm repo add kube-charts https://github.com/TheNewNormal/kube-charts
# Get the latest version of all Charts from repos
helm up

# set etcd endpoint
export ETCDCTL_PEERS=http://$master_vm_ip:2379

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

sleep 2

# generate kubeconfig file
echo Generate kubeconfig file ...
"${res_folder}"/bin/gen_kubeconfig $master_vm_ip
#

# set kubernetes master
export KUBERNETES_MASTER=http://$master_vm_ip:8080
#
echo Waiting for Kubernetes cluster to be ready. This can take a few minutes...
spin='-\|/'
i=1
until curl -o /dev/null http://$master_vm_ip:8080 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
i=1
until ~/kube-cluster/bin/kubectl version | grep 'Server Version' >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\b${spin:i++%${#sp}:1}"; sleep .1; done
i=1
until ~/kube-cluster/bin/kubectl get nodes | grep $node1_vm_ip >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
i=1
until ~/kube-cluster/bin/kubectl get nodes | grep $node2_vm_ip >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
echo " "
# attach label to the nodes
~/kube-cluster/bin/kubectl label nodes $node1_vm_ip node=worker1
~/kube-cluster/bin/kubectl label nodes $node2_vm_ip node=worker2
#
install_k8s_add_ons "$master_vm_ip"
#
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
echo "Installation has finished, Kube Cluster VMs are up and running !!!"
echo " "
echo "Assigned static IP for master VM: $master_vm_ip"
echo "Assigned static IP for node1 VM: $node1_vm_ip"
echo "Assigned static IP for node2 VM: $node2_vm_ip"
echo " "
echo "You can control this App via status bar icon... "
echo " "

echo "Also you can install Deis PaaS (http://deis.io) v2 alpha version with 'install_deis' command ..."
echo " "

cd ~/kube-cluster
# open bash shell
/bin/bash




