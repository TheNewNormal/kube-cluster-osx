#!/bin/bash

#  fetch latest iso
#

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-cluster/.env/resouces_path)

CHANNEL=$(cat ~/kube-cluster/custom.conf | grep CHANNEL= | head -1 | cut -f2 -d"=")

# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-cluster/bin:$PATH

echo " "
echo "Fetching lastest CoreOS $CHANNEL channel ISO ..."
echo " "

cd ~/kube-cluster/
"${res_folder}"/bin/coreos-xhyve-fetch -f custom.conf

echo " "
pause 'Press [Enter] key to continue...'
