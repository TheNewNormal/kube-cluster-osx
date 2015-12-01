#!/bin/bash

# up.command
#

#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-cluster/.env/resouces_path)

# check if iTerm.app exists
App="/Applications/iTerm.app"
if [ ! -d "$App" ]
then
    unzip "${res_folder}"/files/iTerm2.zip -d /Applications/
fi

# copy corectl to bin folder
cp -f "${res_folder}"/bin/corectl ~/kube-cluster/bin
chmod 755 ~/kube-cluster/bin/corectl

# check for password in Keychain
my_password=$(security 2>&1 >/dev/null find-generic-password -wa kube-cluster-app)
if [ "$my_password" = "security: SecKeychainSearchCopyNext: The specified item could not be found in the keychain." ]
then
    echo " "
    echo "Saved password in 'Keychain' is not found: "
    # save user password to Keychain
    save_password
fi

new_vm=0
# check if root disk exists, if not create it
if [ ! -f $HOME/kube-cluster/master-root.img ]; then
    echo " "
    echo "ROOT disk does not exist, it will be created now ..."
    create_root_disk
    new_vm=1
fi

# get master VM's IP
master_vm_ip=$(cat ~/kube-cluster/.env/ip_address_master);

# Start VMs
echo " "
echo "Starting VMs ..."
echo " "
echo -e "$my_password\n" | sudo -S corectl load k8smaster-01.toml
echo -e "$my_password\n" | sudo -S corectl load k8snode-01.toml
echo -e "$my_password\n" | sudo -S corectl load k8snode-02.toml
#

# Set the environment variables
# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-cluster/bin:$PATH

# set etcd endpoint
export ETCDCTL_PEERS=http://$master_vm_ip:2379
# wait till VM is ready
echo " "
echo "Waiting for VM to be ready..."
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
if [ $new_vm = 1 ]
then
    install_k8s_files
    #
    echo "  "
    deploy_fleet_units
fi

echo " "
# set kubernetes master
export KUBERNETES_MASTER=http://$master_vm_ip:8080
echo Waiting for Kubernetes cluster to be ready. This can take a few minutes...
spin='-\|/'
i=1
until curl -o /dev/null -sIf http://$master_vm_ip:8080 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
i=1
until ~/kube-cluster/bin/kubectl get nodes | grep $master_vm_ip >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
#

if [ $new_vm = 1 ]
then
    # attach label to the node
    ~/kube-cluster/bin/kubectl label nodes $master_vm_ip node=worker1
    # copy add-ons files
    cp "${res_folder}"/k8s/*.yaml ~/kube-cluster/kubernetes
    install_k8s_add_ons "$master_vm_ip"
    #
fi
#
echo "kubernetes nodes list:"
~/kube-cluster/bin/kubectl get nodes
echo " "
#

cd ~/kube-cluster/kubernetes

# open bash shell
/bin/bash
