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
echo "Setting up Kubernetes Cluster on OS X"

# add ssh key to custom.conf
echo " "
echo "Reading ssh key from $HOME/.ssh/id_rsa.pub  "
file="$HOME/.ssh/id_rsa.pub"

while [ ! -f "$file" ]
do
    echo " "
    echo "$file not found."
    echo "please run 'ssh-keygen -t rsa' before you continue !!!"
    pause 'Press [Enter] key to continue...'
done

echo " "
echo "$file found, installing ..."
echo "   sshkey = '$(cat $HOME/.ssh/id_rsa.pub)'" >> ~/kube-cluster/settings/k8smaster-01.toml
echo "   sshkey = '$(cat $HOME/.ssh/id_rsa.pub)'" >> ~/kube-cluster/settings/k8snode-01.toml
echo "   sshkey = '$(cat $HOME/.ssh/id_rsa.pub)'" >> ~/kube-cluster/settings/k8snode-02.toml
#

# save user's password to Keychain
save_password
#

# Set release channel
release_channel

# create ROOT disk
create_root_disk

# get master VM's IP
master_vm_ip=$(cat ~/kube-cluster/.env/ip_address_master);

# Get password
my_password=$(security find-generic-password -wa kube-cluster-app)

# Start VMs
cd ~/kube-cluster
echo " "
echo "Starting VMs ..."
echo " "
echo -e "$my_password\n" | sudo -S corectl load ~/kube-cluster/settings/k8smaster-01.toml
echo -e "$my_password\n" | sudo -S corectl load ~/kube-cluster/settings/k8snode-01.toml
echo -e "$my_password\n" | sudo -S corectl load ~/kube-cluster/settings/k8snode-02.toml
#

# waiting for master's VM response to ping
spin='-\|/'
i=1
while ! ping -c1 $master_vm_ip >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
#

# install k8s files on to VMs
install_k8s_files
#

# download latest version fleetctl and helm clients
download_osx_clients
#

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
until ~/kube-cluster/bin/kubectl get nodes | grep $master_vm_ip >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
echo " "
# attach label to the nodes
~/kube-cluster/bin/kubectl label nodes $(corectl ps -j | jq ".[] | select(.Name==\"k8snode-01\") | .PublicIP" | sed -e 's/"\(.*\)"/\1/') node=worker1
~/kube-cluster/bin/kubectl label nodes $(corectl ps -j | jq ".[] | select(.Name==\"k8snode-02\") | .PublicIP" | sed -e 's/"\(.*\)"/\1/') node=worker2
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
echo "Installation has finished, Kube Solo VM is up and running !!!"
echo " "
echo "Assigned static VM's IP: $master_vm_ip"
echo " "
echo "Enjoy Kube Solo on your Mac !!!"
echo " "
echo "You can control this App via status bar icon... "
echo " "

cd ~/kube-cluster
# open bash shell
/bin/bash




