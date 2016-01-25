#!/bin/bash

# up.command
#

#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

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
rsync -r --verbose --exclude 'helm' "${res_folder}"/bin/* ~/kube-cluster/bin/ > /dev/null 2>&1
rm -f ~/kube-cluster/bin/gen_kubeconfig
chmod 755 ~/kube-cluster/bin/*

# add ssh key to Keychain
ssh-add -K ~/.ssh/id_rsa &>/dev/null
#

# check for password in Keychain
my_password=$(security 2>&1 >/dev/null find-generic-password -wa kube-cluster-app)
if [ "$my_password" = "security: SecKeychainSearchCopyNext: The specified item could not be found in the keychain." ]
then
    echo " "
    echo "Saved password could not be found in the 'Keychain': "
    # save user password to Keychain
    save_password
fi

new_vm=0
# check if master's data disk exists, if not create it
if [ ! -f $HOME/kube-cluster/master-data.img ]; then
    echo " "
    echo "Data disks do not exist, they will be created now ..."
    create_data_disk
    new_vm=1
fi

# get password for sudo
my_password=$(security find-generic-password -wa kube-cluster-app)
# reset sudo
sudo -k > /dev/null 2>&1

# Start VMs
cd ~/kube-cluster
echo " "
echo "Starting k8smaster-01 VM ..."
echo " "
echo -e "$my_password\n" | sudo -Sv > /dev/null 2>&1
#
sudo "${res_folder}"/bin/corectl load settings/k8smaster-01.toml 2>&1 | tee ~/kube-cluster/logs/master_vm_up.log
CHECK_VM_STATUS=$(cat ~/kube-cluster/logs/master_vm_up.log | grep "started")
#
if [[ "$CHECK_VM_STATUS" == "" ]]; then
    echo " "
    echo "Master VM has not booted, please check '~/kube-cluster/logs/master_vm_up.log' and report the problem !!! "
    echo " "
    pause 'Press [Enter] key to continue...'
    exit 0
else
    echo "Master VM successfully started !!!" >> ~/kube-cluster/logs/master_vm_up.log
fi

# check if /Users/homefolder is mounted, if not mount it
"${res_folder}"/bin/corectl ssh k8smaster-01 'source /etc/environment; if df -h | grep ${HOMEDIR}; then echo 0; else sudo systemctl restart ${HOMEDIR}; fi' > /dev/null 2>&1
# save master VM's IP
"${res_folder}"/bin/corectl q -i k8smaster-01 | tr -d "\n" > ~/kube-cluster/.env/master_ip_address
# get master VM's IP
master_vm_ip=$("${res_folder}"/bin/corectl q -i k8smaster-01)
#
sleep 2
#
echo " "
echo "Starting k8snode-01 VM ..."
echo -e "$my_password\n" | sudo -Sv > /dev/null 2>&1
#
sudo "${res_folder}"/bin/corectl load settings/k8snode-01.toml 2>&1 | tee ~/kube-cluster/logs/node1_vm_up.log
CHECK_VM_STATUS=$(cat ~/kube-cluster/logs/node1_vm_up.log | grep "started")
#
if [[ "$CHECK_VM_STATUS" == "" ]]; then
    echo " "
    echo "Node1 VM has not booted, please check '~/kube-cluster/logs/node1_vm_up.log' and report the problem !!! "
    echo " "
    pause 'Press [Enter] key to continue...'
    exit 0
else
    echo "Node1 VM successfully started !!!" >> ~/kube-cluster/logs/node1_vm_up.log
fi
# check if /Users/homefolder is mounted, if not mount it
"${res_folder}"/bin/corectl ssh k8snode-01 'source /etc/environment; if df -h | grep ${HOMEDIR}; then echo 0; else sudo systemctl restart ${HOMEDIR}; fi' > /dev/null 2>&1
echo " "
# save node1 VM's IP
"${res_folder}"/bin/corectl q -i k8snode-01 | tr -d "\n" > ~/kube-cluster/.env/node1_ip_address
# get node1 VM's IP
node1_vm_ip=$("${res_folder}"/bin/corectl q -i k8snode-01)
#
#
echo "Starting k8snode-02 VM ..."
echo -e "$my_password\n" | sudo -Sv > /dev/null 2>&1
#
sudo "${res_folder}"/bin/corectl load settings/k8snode-02.toml 2>&1 | tee ~/kube-cluster/logs/node2_vm_up.log
CHECK_VM_STATUS=$(cat ~/kube-cluster/logs/node2_vm_up.log | grep "started")
#
if [[ "$CHECK_VM_STATUS" == "" ]]; then
    echo " "
    echo "Node2 VM has not booted, please check '~/kube-cluster/logs/node2_vm_up.log' and report the problem !!! "
    echo " "
    pause 'Press [Enter] key to continue...'
    exit 0
else
    echo "Node2 VM successfully started !!!" >> ~/kube-cluster/logs/node2_vm_up.log
fi
# check if /Users/homefolder is mounted, if not mount it
"${res_folder}"/bin/corectl ssh k8snode-02 'source /etc/environment; if df -h | grep ${HOMEDIR}; then echo 0; else sudo systemctl restart ${HOMEDIR}; fi' > /dev/null 2>&1
echo " "
# save node2 VM's IP
"${res_folder}"/bin/corectl q -i k8snode-02 | tr -d "\n" > ~/kube-cluster/.env/node2_ip_address
# get node2 VM's IP
node2_vm_ip=$("${res_folder}"/bin/corectl q -i k8snode-02)
###

# Set the environment variables
# set etcd endpoint
export ETCDCTL_PEERS=http://$master_vm_ip:2379
# wait till VM is ready
echo " "
echo "Waiting for k8smaster-01 to be ready..."
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
echo "Waiting for Kubernetes cluster to be ready. This can take a few minutes..."
spin='-\|/'
i=1
until curl -o /dev/null -sIf http://$master_vm_ip:8080 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
i=1
until ~/kube-cluster/bin/kubectl get nodes | grep $node1_vm_ip >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
i=1
until ~/kube-cluster/bin/kubectl get nodes | grep $node2_vm_ip >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
#
echo " "

if [ $new_vm = 1 ]
then
    # attach label to the nodes
    echo " "
    ~/kube-cluster/bin/kubectl label nodes $node1_vm_ip node=worker1
    ~/kube-cluster/bin/kubectl label nodes $node2_vm_ip node=worker2
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
