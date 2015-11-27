#!/bin/bash

#  update OS X clients
#

#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-cluster/.env/resouces_path)

# get VM IP
vm_ip=$(cat ~/kube-cluster/.env/ip_address)

# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-cluster/bin:$PATH

# copy files to ~/kube-cluster/bin
cp -f "${res_folder}"/files/* ~/kube-cluster/bin
# copy xhyve to bin folder
cp -f "${res_folder}"/bin/xhyve ~/kube-cluster/bin
chmod 755 ~/kube-cluster/bin/*

# download latest version of fleetctl client
download_osx_clients
#

echo " "
echo "Update has finished !!!"
pause 'Press [Enter] key to continue...'

