#!/bin/bash

#  update_k8s_versions.command
#  Kube-Cluster for macOS
#
#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-cluster/.env/resouces_path)

# get VMs IPs
master_vm_ip=$("${res_folder}"/bin/corectl q -i k8smaster-01)
node1_vm_ip=$("${res_folder}"/bin/corectl q -i k8snode-01)
node2_vm_ip=$("${res_folder}"/bin/corectl q -i k8snode-02)

# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-cluster/bin:$PATH

# copy files to ~/kube-cluster/bin
cp -f "${res_folder}"/bin/* ~/kube-cluster/bin
rm -f ~/kube-cluster/bin/gen_kubeconfig
chmod 755 ~/kube-cluster/bin/*

echo " "
# download required version of k8s files
k8s_upgrade=0
download_k8s_files_version
if [ $k8s_upgrade -eq 0 ]; then
    exit 0
fi
#

# generate kubeconfig file
echo Generate kubeconfig file ...
"${res_folder}"/bin/gen_kubeconfig $master_vm_ip
echo " "
#

# restart fleet units
echo " "
echo "Restarting fleet units:"
# set fleetctl tunnel
export FLEETCTL_ENDPOINT=http://$master_vm_ip:2379
export FLEETCTL_DRIVER=etcd
export FLEETCTL_STRICT_HOST_KEY_CHECKING=false
cd ~/kube-cluster/fleet
echo " "
echo "Stopping Kubernetes fleet units ..."
~/kube-cluster/bin/fleetctl stop kube-apiserver.service
~/kube-cluster/bin/fleetctl stop kube-controller-manager.service
~/kube-cluster/bin/fleetctl stop kube-scheduler.service
~/kube-cluster/bin/fleetctl stop kube-kubelet.service
~/kube-cluster/bin/fleetctl stop kube-proxy.service
sleep 5
echo " "
echo "Starting Kubernetes fleet units ..."
~/kube-cluster/bin/fleetctl start kube-apiserver.service
~/kube-cluster/bin/fleetctl start kube-controller-manager.service
~/kube-cluster/bin/fleetctl start kube-scheduler.service
~/kube-cluster/bin/fleetctl start kube-kubelet.service
~/kube-cluster/bin/fleetctl start kube-proxy.service
#
sleep 5
echo " "
echo "fleetctl list-units:"
~/kube-cluster/bin/fleetctl list-units
echo " "

# set kubernetes master
export KUBERNETES_MASTER=http://$master_vm_ip:8080
echo Waiting for Kubernetes cluster to be ready. This can take a few minutes...
spin='-\|/'
i=1
until ~/kube-cluster/bin/kubectl version | grep 'Server Version' >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\b${spin:i++%${#sp}:1}"; sleep .1; done
i=1
until ~/kube-cluster/bin/kubectl get nodes | grep $node1_vm_ip >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
i=1
until ~/kube-cluster/bin/kubectl get nodes | grep $node2_vm_ip >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
echo " "
#
echo " "
echo "Kubernetes nodes list:"
~/kube-cluster/bin/kubectl get nodes
echo " "
#
echo "Kubernetes cluster version:"
CLIENT_INSTALLED_VERSION=$(~/kube-cluster/bin/kubectl version | grep "Client Version:" | awk '{print $5}' | awk -v FS='(:"|",)' '{print $2}')
SERVER_INSTALLED_VERSION=$(~/kube-cluster/bin/kubectl version | grep "Server Version:" | awk '{print $5}' | awk -v FS='(:"|",)' '{print $2}')
echo "Client version: $CLIENT_INSTALLED_VERSION"
echo "Server version: $SERVER_INSTALLED_VERSION"
echo " "
#
echo "Cluster info:"
~/kube-cluster/bin/kubectl cluster-info
echo " "

echo "Kubernetes cluster update has finished !!!"
pause 'Press [Enter] key to continue...'
