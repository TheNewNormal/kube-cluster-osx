#!/bin/bash

#  halt.command

# send halt to VMs
~/bin/corectl halt k8snode-01
sleep 2

~/bin/corectl halt k8snode-02
sleep 2

~/bin/corectl halt k8smaster-01