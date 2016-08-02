#!/bin/bash

# destroy extra disk and create new
#

#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-cluster/.env/resouces_path)

LOOP=1
while [ $LOOP -gt 0 ]
do
    VALID_MAIN=0
    echo " "
    echo "VMs will be stopped (if is running) and destroyed !!!"
    echo "Do you want to continue [y/n]"

    read RESPONSE
    XX=${RESPONSE:=Y}

    if [ $RESPONSE = y ]
    then
        VALID_MAIN=1

        # send halt to VMs
        ~/bin/corectl halt k8smaster-01 > /dev/null 2>&1
        ~/bin/corectl halt k8snode-01 > /dev/null 2>&1
        ~/bin/corectl halt k8snode-02 > /dev/null 2>&1

        # delete master and nodes volume images
        rm -f ~/kube-cluster/*.img

        echo "-"
        echo "Done, please start VMs with 'Up' and the new VMs will be recreated ..."
        echo " "
        pause 'Press [Enter] key to continue...'
        LOOP=0
    fi

    if [ $RESPONSE = n ]
    then
        VALID_MAIN=1
        LOOP=0
    fi

    if [ $VALID_MAIN != y ] || [ $VALID_MAIN != n ]
    then
        continue
    fi
done




