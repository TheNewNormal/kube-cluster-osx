#!/bin/bash

#  change_nodes_ram.command

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

#
change_nodes_ram

#
((ram_size=$new_ram_size/1024))

echo "You need to reboot your VMs if they are running or on next VMs' boot new $ram_size GB RAM will be used ..."
echo " "
pause 'Press [Enter] key to continue...'
