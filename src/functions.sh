#!/bin/bash

# shared functions library

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


function pause(){
    read -p "$*"
}

function check_vm_status() {
# check VMs status
status=$(ps aux | grep "[k]ube-solo/bin/xhyve" | awk '{print $2}')
if [ "$status" = "" ]; then
    echo " "
    echo "CoreOS VM is not running, please start VM !!!"
    pause "Press any key to continue ..."
    exit 1
fi
}


function release_channel(){
# Set release channel
LOOP=1
while [ $LOOP -gt 0 ]
do
    VALID_MAIN=0
    echo " "
    echo "Set CoreOS Release Channel:"
    echo " 1)  Alpha "
    echo " 2)  Beta "
    echo " 3)  Stable "
    echo " "
    echo -n "Select an option: "

    read RESPONSE
    XX=${RESPONSE:=Y}

    if [ $RESPONSE = 1 ]
    then
        VALID_MAIN=1
        sed -i "" 's/channel = "stable"/channel = "alpha"/g' ~/kube-cluster/settings/*.toml
        sed -i "" 's/channel = "beta"/channel = "alpha"/g' ~/kube-cluster/settings/*.toml
        channel="Alpha"
        LOOP=0
    fi

    if [ $RESPONSE = 2 ]
    then
        VALID_MAIN=1
        sed -i "" 's/channel = "stable"/channel = "beta"/g' ~/kube-cluster/settings/*.toml
        sed -i "" 's/channel = "alpha"/channel = "beta"/g' ~/kube-cluster/settings/*.toml
        channel="Beta"
        LOOP=0
    fi

    if [ $RESPONSE = 3 ]
    then
        VALID_MAIN=1
        sed -i "" 's/channel = "beta"/channel = "stable"/g' ~/kube-cluster/settings/*.toml
        sed -i "" 's/channel = "alpha"/channel = "stable"/g' ~/kube-cluster/settings/*.toml
        channel="Stable"
        LOOP=0
    fi

    if [ $VALID_MAIN != 1 ]
    then
        continue
    fi
done
}


create_root_disk() {

# Get password
my_password=$(security find-generic-password -wa kube-cluster-app)
echo -e "$my_password\n" | sudo -Sv > /dev/null 2>&1

# create persistent disk for master
cd ~/kube-cluster/
echo "  "
echo "Please type k8smaster-01 ROOT disk size in GBs followed by [ENTER]:"
echo -n [default is 1]:
read disk_size
if [ -z "$disk_size" ]
then
    echo "Creating 1GB disk ..."
    # dd if=/dev/zero of=root.img bs=1024 count=0 seek=$[1024*1*1024]
    mkfile 1g master-root.img &
else
    echo "Creating "$disk_size"GB disk (could take a while for big files) ..."
    # dd if=/dev/zero of=root.img bs=1024 count=0 seek=$[1024*$disk_size*1024]
    mkfile "$disk_size"g master-root.img &
fi
echo " "
spin='-\|/'
i=1
until ! ps aux | grep '[m]kfile "$disk_size"g master-root.img' >/dev/null 2>&1 ; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done

#

# create persistent disks for nodes
cd ~/kube-cluster/
echo "  "
echo "Please type k8snodes ROOT disk size in GBs followed by [ENTER]:"
echo -n [default is 5]:
read disk_size
if [ -z "$disk_size" ]
then
    echo "Creating 5GB disk for k8snode-01 ..."
    # dd if=/dev/zero of=node-01-root.img bs=1024 count=0 seek=$[1024*5*1024]
    mkfile 5g node-01-root.img &
    echo " "
    spin='-\|/'
    i=1
    until ! ps aux | grep '[m]kfile "$disk_size"g node-01-root.img' >/dev/null 2>&1 ; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
    #
    echo " "
    echo "Creating 5GB disk for k8snode-02 ..."
    # dd if=/dev/zero of=node-02-root.img bs=1024 count=0 seek=$[1024*5*1024]
    mkfile 5g node-02-root.img &
    echo " "
    spin='-\|/'
    i=1
    until ! ps aux | grep '[m]kfile "$disk_size"g node-02-root.img' >/dev/null 2>&1 ; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
    #
else
    echo "Creating "$disk_size"GB disk for k8snode-01 (could take a while for big files) ..."
    # dd if=/dev/zero of=root.img bs=1024 count=0 seek=$[1024*$disk_size*1024]
    mkfile "$disk_size"g node-01-root.img &
    echo " "
    spin='-\|/'
    i=1
    until ! ps aux | grep '[m]kfile "$disk_size"g node-01-root.img' >/dev/null 2>&1 ; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
    #
    echo " "
    echo "Creating "$disk_size"GB disk for k8snode-02 (could take a while for big files) ..."
    # dd if=/dev/zero of=root.img bs=1024 count=0 seek=$[1024*$disk_size*1024]
    mkfile "$disk_size"g node-02-root.img &
    echo " "
    spin='-\|/'
    i=1
    until ! ps aux | grep '[m]kfile "$disk_size"g node-02-root.img' >/dev/null 2>&1 ; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
fi
#

### format ROOT disks
echo " "
echo "Formating k8smaster-01 ROOT disk ..."
echo -e "$my_password\n" | sudo -S corectl load ~/kube-cluster/settings/k8smaster-01-format-root.toml 2>&1 | grep IP | awk -v FS="(IP | and)" '{print $2}' > ~/kube-cluster/.env/ip_address_master
echo " "
echo "Formating k8snodes1/2 ROOT disks ..."
echo -e "$my_password\n" | sudo -S corectl load ~/kube-cluster/settings/node-format-root.toml 2>&1 | grep IP | awk -v FS="(IP | and)" '{print $2}' > /dev/null
#
echo " "
echo "ROOT disks got created and formated... "
echo "---"
###

}

function download_osx_clients() {
# download fleetctl file
LATEST_RELEASE=$(ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no core@$vm_ip 'fleetctl version' | cut -d " " -f 3- | tr -d '\r')
cd ~/kube-cluster/bin
echo "Downloading fleetctl v$LATEST_RELEASE for OS X"
curl -L -o fleet.zip "https://github.com/coreos/fleet/releases/download/v$LATEST_RELEASE/fleet-v$LATEST_RELEASE-darwin-amd64.zip"
unzip -j -o "fleet.zip" "fleet-v$LATEST_RELEASE-darwin-amd64/fleetctl"
rm -f fleet.zip
echo "fleetctl was copied to ~/kube-cluster/bin "

# get lastest OS X helm version from bintray
bin_version=$(curl -I https://bintray.com/deis/helm-ci/helm/_latestVersion | grep "Location:" | sed -n 's%.*helm/%%;s%/view.*%%p')
echo "Downloading latest version of helm for OS X"
curl -L "https://dl.bintray.com/deis/helm-ci/helm-$bin_version-darwin-amd64.zip" -o helm.zip
unzip -o helm.zip
rm -f helm.zip
echo "helm was copied to ~/kube-cluster/bin "
#

}


function download_k8s_files() {
#
cd ~/kube-cluster/tmp

# get latest k8s version
function get_latest_version_number {
    local -r latest_url="https://storage.googleapis.com/kubernetes-release/release/latest.txt"
    curl -Ss ${latest_url}
}

K8S_VERSION=$(get_latest_version_number)

# download latest version of kubectl for OS X
cd ~/kube-cluster/tmp
echo "Downloading kubectl $K8S_VERSION for OS X"
curl -k -L https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/darwin/amd64/kubectl >  ~/kube-cluster/kube/kubectl
chmod 755 ~/kube-cluster/kube/kubectl
echo "kubectl was copied to ~/kube-cluster/kube"
echo " "

# clean up tmp folder
rm -rf ~/kube-cluster/tmp/*

# download setup-network-environment binary
echo "Downloading setup-network-environment"
curl -L https://github.com/kelseyhightower/setup-network-environment/releases/download/1.0.1/setup-network-environment > ~/kube-cluster/tmp/setup-network-environment
#
# download latest version of k8s binaries for CoreOS
echo "Downloading latest version of Kubernetes"
# master
bins=( kubectl kubelet kube-proxy kube-apiserver kube-scheduler kube-controller-manager )
for b in "${bins[@]}"; do
    curl -k -L https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/linux/amd64/$b > ~/kube-cluster/tmp/$b
done
chmod a+x *
# download easy-rsa
curl -k -L https://storage.googleapis.com/kubernetes-release/easy-rsa/easy-rsa.tar.gz > master/easy-rsa.tar.gz
#
tar czvf master.tgz *
cp -f master.tgz ~/kube-cluster/kube/
# clean up tmp folder
rm -rf ~/kube-cluster/tmp/*
echo " "

# nodes
bins=( kubectl kubelet kube-proxy )
for b in "${bins[@]}"; do
    curl -k -L https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/linux/amd64/$b > ~/kube-cluster/tmp/$b
done
chmod a+x *
tar czvf nodes.tgz *
cp -f nodes.tgz ~/kube-cluster/kube/
# clean up tmp folder
rm -rf ~/kube-cluster/tmp/*
echo " "

# get VM IP
master_ip=$(cat ~/kube-cluster/.env/ip_address_master)

# install k8s files
install_k8s_files

}


function check_for_images() {
# Check if set channel's images are present
CHANNEL=$(cat ~/kube-cluster/custom.conf | grep CHANNEL= | head -1 | cut -f2 -d"=")
LATEST=$(ls -r ~/kube-cluster/imgs/${CHANNEL}.*.vmlinuz | head -n 1 | sed -e "s,.*${CHANNEL}.,," -e "s,.coreos_.*,," )
if [[ -z ${LATEST} ]]; then
    echo "Couldn't find anything to load locally (${CHANNEL} channel)."
    echo "Fetching lastest $CHANNEL channel ISO ..."
    echo " "
    cd ~/kube-cluster/
    "${res_folder}"/bin/coreos-xhyve-fetch -f custom.conf
fi
}


function deploy_fleet_units() {
# deploy fleet units from ~/kube-cluster/fleet
cd ~/kube-cluster/fleet
echo "Starting all fleet units in ~/kube-cluster/fleet:"
fleetctl start fleet-ui.service
fleetctl start kube-apiserver.service
fleetctl start kube-controller-manager.service
fleetctl start kube-scheduler.service
fleetctl start kube-kubelet.service
fleetctl start kube-proxy.service
echo " "
echo "fleetctl list-units:"
fleetctl list-units
echo " "

}


function install_k8s_files {
# install k8s files on to VM
echo " "
echo "Installing Kubernetes files on to Master..."
cd ~/kube-cluster/kube
scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet master.tgz core@$vm_ip:/home/core
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet core@$vm_ip 'sudo /usr/bin/mkdir -p /opt/bin && sudo tar xzf /home/core/kube.tgz -C /opt/bin && sudo chmod 755 /opt/bin/*'
echo "Done with k8smaster-01 "
echo " "


}


function install_k8s_add_ons {
echo " "
echo "Creating kube-system namespace ..."
~/kube-cluster/bin/kubectl create -f ~/kube-cluster/kubernetes/kube-system-ns.yaml
#
sed -i "" "s/_MASTER_IP_/$1/" ~/kube-cluster/kubernetes/skydns-rc.yaml
echo " "
echo "Installing SkyDNS ..."
~/kube-cluster/bin/kubectl create -f ~/kube-cluster/kubernetes/skydns-rc.yaml
~/kube-cluster/bin/kubectl create -f ~/kube-cluster/kubernetes/skydns-svc.yaml
#
echo " "
echo "Installing Kubernetes UI ..."
~/kube-cluster/bin/kubectl create -f ~/kube-cluster/kubernetes/kube-ui-rc.yaml
~/kube-cluster/bin/kubectl create -f ~/kube-cluster/kubernetes/kube-ui-svc.yaml
sleep 1
# clean up kubernetes folder
rm -f ~/kube-cluster/kubernetes/kube-system-ns.yaml
rm -f ~/kube-cluster/kubernetes/skydns-rc.yaml
rm -f ~/kube-cluster/kubernetes/skydns-svc.yaml
rm -f ~/kube-cluster/kubernetes/kube-ui-rc.yaml
rm -f ~/kube-cluster/kubernetes/kube-ui-svc.yaml
echo " "
}


function save_password {
# save user's password to Keychain
echo "  "
echo "Your Mac user's password will be saved in to 'Keychain' "
echo "and later one used for 'sudo' command to start VM !!!"
echo " "
echo "This is not the password to access VM via ssh or console !!!"
echo " "
echo "Please type your Mac user's password followed by [ENTER]:"
read -s my_password
passwd_ok=0

# check if sudo password is correct
while [ ! $passwd_ok = 1 ]
do
    # reset sudo
    sudo -k
    # check sudo
    echo -e "$my_password\n" | sudo -Sv > /dev/null 2>&1
    CAN_I_RUN_SUDO=$(sudo -n uptime 2>&1|grep "load"|wc -l)
    if [ ${CAN_I_RUN_SUDO} -gt 0 ]
    then
        echo "The sudo password is fine !!!"
        echo " "
        passwd_ok=1
    else
        echo " "
        echo "The password you entered does not match your Mac user password !!!"
        echo "Please type your Mac user's password followed by [ENTER]:"
        read -s my_password
    fi
done

security add-generic-password -a kube-cluster-app -s kube-cluster-app -w $password -U
}


function clean_up_after_vm {
sleep 3

# get App's Resources folder
res_folder=$(cat ~/kube-cluster/.env/resouces_path)

# Get password
my_password=$(security find-generic-password -wa kube-cluster-app)

# Stop webserver
kill $(ps aux | grep "[k]ube-solo-web" | awk {'print $2'})

# kill all kube-cluster/bin/xhyve instances
# ps aux | grep "[k]ube-solo/bin/xhyve" | awk '{print $2}' | sudo -S xargs kill | echo -e "$my_password\n"
echo -e "$my_password\n" | sudo -S pkill -f [k]ube-solo/bin/xhyve
#
echo -e "$my_password\n" | sudo -S pkill -f "${res_folder}"/bin/uuid2mac

# kill all other scripts
pkill -f [K]ube-Solo.app/Contents/Resources/start_VM.command
pkill -f [K]ube-Solo.app/Contents/Resources/bin/get_ip
pkill -f [K]ube-Solo.app/Contents/Resources/bin/get_mac
pkill -f [K]ube-Solo.app/Contents/Resources/bin/mac2ip
pkill -f [K]ube-Solo.app/Contents/Resources/fetch_latest_iso.command
pkill -f [K]ube-Solo.app/Contents/Resources/update_k8s.command
pkill -f [K]ube-Solo.app/Contents/Resources/update_osx_clients_files.command
pkill -f [K]ube-Solo.app/Contents/Resources/change_release_channel.command

}


function kill_xhyve {
sleep 3

# get App's Resources folder
res_folder=$(cat ~/kube-cluster/.env/resouces_path)

# Get password
my_password=$(security find-generic-password -wa kube-cluster-app)

# kill all kube-cluster/bin/xhyve instances
echo -e "$my_password\n" | sudo -S pkill -f [k]ube-solo/bin/xhyve

}

