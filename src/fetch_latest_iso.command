#!/bin/bash

#  fetch latest iso
#

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-cluster/.env/resouces_path)

# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-cluster/bin:$PATH

# get channel from the config file
CHANNEL=$(cat ~/kube-cluster/settings/k8smaster-01.toml | grep "channel =" | head -1 | cut -f2 -d"=" | /usr/bin/sed -e 's/ "\(.*\)"/\1/')

echo " "
echo "Fetching lastest CoreOS $CHANNEL channel ISO ..."
echo " "
#
"${res_folder}"/bin/corectl pull --channel="$CHANNEL" 2>&1 | tee ~/kube-cluster/tmp/check_channel
CHECK_CHANNEL=$(cat ~/kube-cluster/tmp/check_channel | grep "already available")
#
if [[ "$CHECK_CHANNEL" == "" ]]; then
    echo " "
    echo "You need to reload your VMs to be booted from the lastest version !!! "
fi
rm -f ~/kube-cluster/tmp/check_channel
echo " "
pause 'Press [Enter] key to continue...'
