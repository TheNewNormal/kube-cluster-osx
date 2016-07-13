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

new_vm=0
# check if master's data disk exists, if not create it
if [ ! -f $HOME/kube-cluster/master-data.img ]; then
    echo " "
    echo "Data disks do not exist, they will be created now ..."
    create_data_disk
    new_vm=1
fi

# start cluster VMs
start_vms

# generate kubeconfig file
if [ ! -f $HOME/kube-cluster/kube/kubeconfig ]; then
    echo Generating kubeconfig file ...
    "${res_folder}"/bin/gen_kubeconfig $master_vm_ip
    echo " "
fi

# Set the environment variables
# set etcd endpoint
export ETCDCTL_PEERS=http://$master_vm_ip:2379
# wait till etcd is ready
echo " "
echo "Waiting for etcd service to be ready on k8smaster-01 VM..."
spin='-\|/'
i=1
until curl -o /dev/null http://$master_vm_ip:2379 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
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
# check if k8s files are on master VM
if /usr/local/sbin/corectl ssh k8smaster-01 '[ -f /opt/bin/kube-apiserver ]' &> /dev/null
then
    new_vm=0
else
    new_vm=1
fi
#
# check if k8s files are on node1 VM
if /usr/local/sbin/corectl ssh k8snode-01 '[ -f /opt/bin/kubelet ]' &> /dev/null
then
    new_vm=0
else
    new_vm=1
fi
#
# check if k8s files are on node2 VM
if /usr/local/sbin/corectl ssh k8snode-02 '[ -f /opt/bin/kubelet ]' &> /dev/null
then
    new_vm=0
else
    new_vm=1
fi

#
if [ $new_vm = 1 ]
then
    # check internet from VM
    echo " "
    echo "Checking internet availablity on master VM..."
    check_internet_from_vm
    #
    install_k8s_files
    #
    echo "  "
    deploy_fleet_units
fi

echo " "
# set kubernetes master
export KUBERNETES_MASTER=http://$master_vm_ip:8080
echo "Waiting for Kubernetes cluster to be ready. This can take a few minutes..."
spin='-\|/'
i=1
until curl -o /dev/null -sIf http://$master_vm_ip:8080 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
i=1
until ~/kube-cluster/bin/kubectl get nodes | grep -w "k8snode-01" | grep -w "Ready" >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
i=1
until ~/kube-cluster/bin/kubectl get nodes | grep -w "k8snode-02" | grep -w "Ready" >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
#i=1
#until ~/kube-cluster/bin/kubectl get nodes | grep -w [R]eady >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
#
echo " "

if [ $new_vm = 1 ]
then
    # attach label to the nodes
    echo " "
    ~/kube-cluster/bin/kubectl label nodes k8snode-01 node=worker1
    ~/kube-cluster/bin/kubectl label nodes k8snode-02 node=worker2
    # copy add-ons files
    cp "${res_folder}"/k8s/*.yaml ~/kube-cluster/kubernetes
    install_k8s_add_ons "$master_vm_ip"
    #
fi
#
echo "kubectl get nodes:"
~/kube-cluster/bin/kubectl get nodes
echo " "
#

cd ~/kube-cluster/kubernetes

# open bash shell
/bin/bash
