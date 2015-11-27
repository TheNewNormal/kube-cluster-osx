Kubernetes Cluster for OS X (work in progress)
============================
![k8s-multinode](k8s-multinode.png)

**Kube-Cluster for Mac OS X** is a Mac Status bar App which works like a wrapper around the [corectl](https://github.com/TheNewNormal/corectl) command line tool and bootstraps Kubernetes cluster with one master and two nodes based on [CoreOS VMs](https://coreos.com).

Includes [Helm](https://helm.sh) - The Kubernetes Package Manager. 

![Kube-Cluster](kube-cluster-osx.png "Kubernetes-Cluster")

Download
--------
Head over to the [Releases Page](https://github.com/TheNewNormal/kube-cluster-osx/releases) to grab the latest release.


How to install Kube-Cluster
----------

**WARNING**
 -----------
  - You must be running **OS X 10.10.3** Yosemite or later and 2010 or later Mac for this to work.

  - If you are, or were, running any version of VirtualBox, prior to 4.3.30 or 5.0,
and attempt to run xhyve your system will immediately crash as a kernel panic is
triggered. This is due to a VirtualBox bug (that got fixed in newest VirtualBox
versions) as VirtualBox wasn't playing nice with OSX's Hypervisor.framework used
by [xhyve](https://github.com/mist64/xhyve).


###Install:

Start the `Kube-Cluster` and from menu `Setup` choose `Initial setup of Kube-Cluster` and the install will do the following:

* All dependent files/folders will be put under `kube-cluster` folder in the user's home folder e.g /Users/someuser/kube-cluster
* User's Mac password will be stored in `OS X KeyChain`, it will be used for sudo command which needs to be used starting VM with `corectl`
* ISO images are stored under `~/.coreos/images`.
That allows to share the same images between different `corectl' based Apps and also speeds up this App's reinstall
* user-data file will have fleet, etcd and flannel set
* Will download latest CoreOS ISO image and run `corectl` to initialise VM 
* When you first time do install or 'Up' after destroying Kube-Cluster setup, k8s binary files (with the version which was available when the App was built) get copied to CoreOS VM, this speeds up Kubernetes cluster setup. To update Kubernetes just run from menu 'Updates' - Update Kubernetes and OS X kubectl.
* It will install `fleetctl, etcdctl and kubectl` to `~/kube-cluster/bin/`
* Kubernetes services will be installed with fleet units which are placed in `~/kube-cluster/fleet`, this allows very easy updates to fleet units if needed.
* [Fleet-UI](http://fleetui.com) via unit file will be installed to check running fleet units
* [Kubernetes UI](http://kubernetes.io/v1.1/docs/user-guide/ui.html) will be instlled as an add-on
* Also [DNS Add On](https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/dns) will be installed
* Via assigned static IPs (which will be shown on first boot and will survive VMs reboots) you can access any port on any CoreOS VM
* Root persistant disks for VMs will be created and mounted to `/` so data will survive VMs reboots. 

How it works
------------

Just start `Kube-Cluster` application and you will find a small icon with the Kubernetes logo in the Status Bar.

* There you can `Up`, `Halt`, `Reload` CoreOS VMs
* Under `Up` and `OS Shell` OS Shell (terminal) will have such environment set:
````
1) kubernetes master - export KUBERNETES_MASTER=http://192.168.64.xxx:8080
2) etcd endpoint - export ETCDCTL_PEERS=http://192.168.64.xxx:2379
3) fleetctl endpoint - export FLEETCTL_ENDPOINT=http://192.168.64.xxx:2379
4) fleetctl driver - export FLEETCTL_DRIVER=etcd
5) Path to ~/kube-cluster/bin where etcdctl, fleetctl and kubernetes binaries are stored
````

* `Updates/Update Kubernetes cluster and OS X kubectl` will update to latest stable version of Kubernetes.
*`Updates/Update OS X fleetctl and helm clients` will update fleetctl to the same versions as Kube-Cluster Master runs and helm to the latest version.
* `Updates/Force CoreOS update` will be run `sudo update_engine_client -update` on each CoreOS VM.
* `Updates/Check updates for CoreOS vbox` will update CoreOS VM vagrant box.
*
* `SSH to k8smaster01 and k8snode-01/02` menu options will open VM shells
* `node1/2 cAdvisor` will open cAdvisor URL in default browser
* [Fleet-UI](http://fleetui.com) dashboard will show running fleet units and etc
* [Kubernetes-UI](https://github.com/GoogleCloudPlatform/kubernetes/tree/master/www) (contributed by [Kismatic.io](http://kismatic.io/)) will show nice Kubernetes Dashboard, where you can check Nodes, Pods, Replication Controllers and etc.



Example ouput of succesfull CoreOS + Kubernetes cluster install:

````
$ 
etcd cluster:
/registry
/coreos.com

fleetctl list-machines:
MACHINE		IP		METADATA
9b88a46c...	192.168.64.3	role=node
d0c68677...	192.168.64.4	role=node
f93b555e...	192.168.64.2	role=control

fleetctl list-units:
UNIT				MACHINE				ACTIVE	SUB
fleet-ui.service				f93b555e.../192.168.64.2	active	running
kube-apiserver.service			f93b555e.../192.168.64.2	active	running
kube-controller-manager.service	f93b555e.../192.168.64.2	active	running
kube-kubelet.service			9b88a46c.../192.168.64.3	active	running
kube-kubelet.service			d0c68677.../192.168.64.4	active	running
kube-proxy.service				9b88a46c.../192.168.64.3	active	running
kube-proxy.service				d0c68677.../192.168.64.4	active	running
kube-scheduler.service			f93b555e.../192.168.64.2	active	running

k8s nodes list:
NAME                LABELS              STATUS
192.168.64.3       node=worker1        Ready
192.168.64.4       node=worker2        Ready

````




Usage
------------

You're now ready to use Kubernetes cluster.

Some examples to start with [Kubernetes examples](https://github.com/kubernetes/kubernetes/tree/master/examples).

Other links
-----------
* A solo Kubernetes Cluster VM App can be found here [Kube-Solo for OS X](https://github.com/TheNewNormal/kube-solo-osx).

* A standalone one CoreOS VM App (good for docker images building and testing) can be found here [CoreOS VM for OS X](https://github.com/TheNewNormal/coreos-osx).

* CoreOS Cluster App without Kubernetes can be found here [CoreOS Cluster for OS X](https://github.com/rimusz/coreos-osx-cluster).
