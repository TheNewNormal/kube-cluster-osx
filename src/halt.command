#!/bin/bash

#  halt.command

# send halt to VMs
/usr/local/sbin/corectl halt k8snode-01
sleep 2
/usr/local/sbin/corectl halt k8snode-02
sleep 2
/usr/local/sbin/corectl halt k8smaster-01