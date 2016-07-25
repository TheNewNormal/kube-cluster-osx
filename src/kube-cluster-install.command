#!/bin/bash

#  kube-cluster-install.command
#

    # create in "kube-cluster" all required folders and files at user's home folder where all the data will be stored
    mkdir ~/kube-cluster
    mkdir ~/kube-cluster/tmp
    mkdir ~/kube-cluster/logs
    mkdir ~/kube-cluster/bin
    mkdir ~/kube-cluster/cloud-init
    mkdir ~/kube-cluster/settings
    mkdir ~/kube-cluster/fleet
    mkdir ~/kube-cluster/kubernetes
    mkdir ~/kube-cluster/kube

    # cd to App's Resources folder
    cd "$1"

    # copy bin files to ~/kube-cluster/bin
    cp -f "$1"/bin/* ~/kube-cluster/bin
    rm -f ~/kube-cluster/bin/gen_kubeconfig
    chmod 755 ~/kube-cluster/bin/*

    # copy user-data
    cp -f "$1"/cloud-init/* ~/kube-cluster/cloud-init

    # copy settings
    cp -f "$1"/settings/* ~/kube-cluster/settings

    # copy k8s files
    cp "$1"/k8s/kubectl ~/kube-cluster/kube
    chmod 755 ~/kube-cluster/kube/kubectl
    cp "$1"/k8s/add-ons/*.yaml ~/kube-cluster/kubernetes
    # linux binaries
    cp "$1"/k8s/kube.tgz ~/kube-cluster/kube

    # copy fleetctl
    cp -f "$1"/files/fleetctl ~/kube-cluster/bin

    # copy fleet units
    cp -R "$1"/fleet/ ~/kube-cluster/fleet
    #

    # check if iTerm.app exists
    App="/Applications/iTerm.app"
    if [ ! -d "$App" ]
    then
        unzip "$1"/files/iTerm2.zip -d /Applications/
    fi

    # initial init
    open -a iTerm.app "$1"/first-init.command

