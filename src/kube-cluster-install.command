#!/bin/bash

#  kube-cluster-install.command
#

    # create in "kube-cluster" all required folders and files at user's home folder where all the data will be stored
    mkdir -p ~/.coreos-xhyve/imgs
    mkdir ~/kube-cluster
    ln -s ~/.coreos-xhyve/imgs ~/kube-cluster/imgs
    mkdir ~/kube-cluster/tmp
    mkdir ~/kube-cluster/bin
    mkdir ~/kube-cluster/cloud-init
    mkdir ~/kube-cluster/fleet
    mkdir ~/kube-cluster/kubernetes
    mkdir ~/kube-cluster/kube

    # cd to App's Resources folder
    cd "$1"

    # copy files to ~/kube-cluster/bin
    cp -f "$1"/files/* ~/kube-cluster/bin
    rm -f ~/kube-cluster/bin/iTerm2.zip
    # copy xhyve to bin folder
    cp -f "$1"/bin/xhyve ~/kube-cluster/bin
    chmod 755 ~/kube-cluster/bin/*

    # copy user-data
    cp -f "$1"/settings/user-data ~/kube-cluster/cloud-init
    cp -f "$1"/settings/user-data-format-root ~/kube-cluster/cloud-init

    # copy custom.conf
    cp -f "$1"/settings/custom.conf ~/kube-cluster

    # copy k8s files
    cp "$1"/k8s/kubectl ~/kube-cluster/kube
    chmod 755 ~/kube-cluster/kube/kubectl
    cp "$1"/k8s/*.yaml ~/kube-cluster/kubernetes
    # linux binaries
    cp "$1"/k8s/kube.tgz ~/kube-cluster/kube

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

