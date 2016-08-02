#!/bin/bash

#  update macOS clients
#

#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-cluster/.env/resouces_path)

# get master VM's IP
master_vm_ip=$(~/bin/corectl q -i k8smaster-01)

# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-cluster/bin:$PATH

# copy files to ~/kube-cluster/bin
cp -f "${res_folder}"/bin/* ~/kube-cluster/bin
chmod 755 ~/kube-cluster/bin/*

# download latest version of fleetctl and helmc clients
download_osx_clients
#

echo " "
echo "Update has finished !!!"
pause 'Press [Enter] key to continue...'

