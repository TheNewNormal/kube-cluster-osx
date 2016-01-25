#!/bin/bash

#  change release channel
#

#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# Set release channel
release_channel

#
echo " "
echo "CoreOS release channel was updated to '$channel' !!!"
echo "You need to reload your VMs if they are running or on next VMs' boot new '$channel' ISO will be used ..."
echo " "
pause 'Press [Enter] key to continue...'
