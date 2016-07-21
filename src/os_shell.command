#!/bin/bash

#  Pre-set OS shell
#
###DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
###source "${DIR}"/functions.sh

# add ssh key to Keychain
ssh-add -K ~/.ssh/id_rsa &>/dev/null

# get App's Resources folder
res_folder=$(cat ~/kube-cluster/.env/resouces_path)

# get master VM's IP
master_vm_ip=$(/usr/local/sbin/corectl q -i k8smaster-01)

# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-cluster/bin:$PATH

# set etcd endpoint
export ETCDCTL_PEERS=http://$master_vm_ip:2379
echo " "

# set fleetctl endpoint
export FLEETCTL_TUNNEL=
export FLEETCTL_ENDPOINT=http://$master_vm_ip:2379
export FLEETCTL_DRIVER=etcd
export FLEETCTL_STRICT_HOST_KEY_CHECKING=false
echo "fleetctl list-units:"
fleetctl list-units
echo " "

# set kubernetes master
export KUBERNETES_MASTER=http://$master_vm_ip:8080
echo "kubectl get nodes:"
kubectl get nodes
echo " "

cd ~/kube-cluster

# open user's preferred shell
if [[ ! -z "$SHELL" ]]; then
    $SHELL
else
    /bin/bash
fi
