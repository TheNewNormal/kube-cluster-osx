Easy Kubernetes Cluster for macOS
============================

**Kube-Cluster for macOS** is a `status bar app` which allows in an easy way to bootstrap and control multi-node (master+ two nodes) Kubernetes cluster on three [CoreOS](https://coreos.com) VMs.

![k8s-multinode](k8s-multinode.png)

It leverages **macOS native Hypervisor virtualisation framework** of using [corectl](https://github.com/TheNewNormal/corectl) command line tool, so there are no needs to use VirtualBox or any other virtualisation software anymore.

**Includes:** [Helm Classic](https://helm.sh) - The Kubernetes Package Manager and an option from shell to install [Deis Workflow](https://deis.com) on top of Kubernetes: `$ install_deis`

**Kube-Cluster App** can be used together with [CoreOS VM App](https://github.com/TheNewNormal/coreos-osx) which allows to build Docker containers and both apps have access to the same local Docker registry hosted by [Corectl App](https://github.com/TheNewNormal/corectl.app).

**App's menu** looks as per image below:

![Kube-Cluster](kube-cluster-osx.png "Kubernetes-Cluster")

Download
--------
Head over to the [Releases Page](https://github.com/TheNewNormal/kube-cluster-osx/releases) to grab the latest release.


How to install Kube-Cluster
----------

**Requirements**
 -----------
  - **macOS 10.10.3** Yosemite or later 
  - Mac 2010 or later for this to work
  - **Note: [Corectl App](https://github.com/TheNewNormal/corectl.app) must be installed, which will serve as `corectld` server daemon control.**
  - [iTerm2](https://www.iterm2.com/) is required, if not found the app it will install it by itself.


###Install:

- Download [Corectl App](https://github.com/TheNewNormal/corectl.app) `latest dmg` from the [Releases Page](https://github.com/TheNewNormal/corectl.app/releases) and install it to `/Applications` folder, it allows to start/stop/update [corectl](https://github.com/TheNewNormal/corectl) tools needed to run CoreOS VMs on macOS
- Open downloaded `dmg` file and drag the App e.g. to your Desktop. Start the `Kube-Cluster` and `Initial setup of Kube-Cluster VMs` will run, then follow the instructions there.

**TL;DR**

- App's files are installed to `~/kube-cluster` folder
- App will bootstrap `master + two nodes` Kubernetes cluster on three VMs.
- Mac user home folder is automaticly mounted via NFS (it has to work on Mac end of course) to to Node VMs `/Users/my_user`:`/Users/my_user` on each boot, check the [PV example](https://github.com/TheNewNormal/kube-cluster-osx/blob/master/examples/pv/nfs-pv-mount-on-pod.md) how to use Persistent Volumes.
- After successful install you can control kube-cluster VMs via `kcluster` cli as well. Cli resides in `~/kube-cluster/bin` folder and has simple commands: `kcluster start|stop|status|ip`. Just copy the `kcluster` to your shell pre-set path.

**The install will do the following:**

* All dependent files/folders will be put under `kube-cluster` folder in the user's home folder e.g `/Users/someuser/kube-cluster`
* user-data file will have fleet, etcd and flannel set
* Will download latest CoreOS ISO image (if there is no such) and run `corectl` to initialise VM 
* When you first time do install or 'Up' after destroying Kube-Cluster setup, k8s binary files (with the version which was available when the App was built) get copied to CoreOS VMs, this speeds up Kubernetes cluster setup. 
* It will install `fleetctl, kubectl, helmc and deis` clients to `~/kube-cluster/bin/`
* Kubernetes services will be installed with fleet units which are placed in `~/kube-cluster/fleet`, this allows very easy updates to fleet units if needed.
* [Fleet-UI](http://fleetui.com) via unit file will be installed to check running fleet units
* [Kubernetes Dashboard](http://kubernetes.io/docs/user-guide/ui/), [DNS](https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/dns) and [Kubedash](https://github.com/kubernetes/kubedash) will be instlled as add-ons
* Via assigned static IPs (which will be shown on first boot and will survive VMs reboots) you can access any port on any CoreOS VM
* Persistent sparse disks (QCow2) `xxx-data.img` will be created and mounted to VMs as `/data` for these mount binds and other folders:

```
/data/var/lib/docker -> /var/lib/docker
/data/var/lib/rkt -> /var/lib/rkt
/var/lib/kubelet sym linked to /data/kubelet
/data/opt/bin
/data/var/lib/etcd2
/data/kubernetes
``` 

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
5) Path to ~/kube-cluster/bin where fleetctl, helmc, deis and kubectl are stored
````

* `Updates/Update Kubernetes to latest stable version` will update to latest stable version of Kubernetes.
* `Updates\Change Kubernetes version` allows you to insatll any Kubernetes version available on github.com.
* `Updates/Update macOS fleetctl, helmc and deis clients` will update fleetctl to the same versions as Kube-Cluster Master runs and helmc and deis to the latest versions.
* `SSH to k8smaster01 and k8snode-01/02` menu options will open VMs shell
* [Fleet-UI](http://fleetui.com) dashboard will show running fleet units and etc
* [Kubernetes Dashboard](http://kubernetes.io/docs/user-guide/ui/) will show nice Kubernetes Dashboard, where you can check Nodes, Pods, Replication, Deployments, Service Controllers, deploy Apps and etc.
* [Kubedash](https://github.com/kubernetes/kubedash) is a performance analytics UI for Kubernetes Clusters


Example ouput of succesfull CoreOS + Kubernetes cluster install:

````
fleetctl list-units:
UNIT							MACHINE						ACTIVE		SUB
fleet-ui.service				78ea6428.../192.168.64.5	active		running
kube-apiserver.service			78ea6428.../192.168.64.5	active		running
kube-controller-manager.service	78ea6428.../192.168.64.5	active		running
kube-scheduler.service			78ea6428.../192.168.64.5	active		running
kube-kubelet.service			1d00e269.../192.168.64.6	active		running
kube-kubelet.service			de9127a5.../192.168.64.7	active		running
kube-proxy.service				1d00e269.../192.168.64.6	active		running
kube-proxy.service				de9127a5.../192.168.64.7	active		running

Waiting for Kubernetes cluster to be ready. This can take a few minutes...
\...

Waiting for Kubernetes nodes to be ready. This can take a bit...
-...

node "k8snode-01" labeled
node "k8snode-02" labeled

Creating kube-system namespace ...

Installing SkyDNS ...
replicationcontroller "kube-dns-v17" created
service "kube-dns" created

Installing Kubernetes UI ...
replicationcontroller "kubernetes-dashboard-v1.1.0" created
service "kubernetes-dashboard" created

Installing Kubedash ...
deployment "kubedash" created
service "kubedash" created

kubectl get nodes:
NAME         STATUS    AGE
k8snode-01   Ready     6s
k8snode-02   Ready     6s
````




Usage
------------

You're now ready to use Kubernetes cluster.

Some examples to start with [Kubernetes examples](http://kubernetes.io/docs/samples/).

Other CoreOS VM based Apps for macOS
-----------
* Kubernetes Solo Cluster VM App can be found here [Kube-Solo for macOS](https://github.com/TheNewNormal/kube-solo-osx).

* Standalone CoreOS VM App (good for docker images building and testing) can be found here [CoreOS VM for macOS](https://github.com/TheNewNormal/coreos-osx).

* CoreOS Cluster App without Kubernetes can be found here [CoreOS Cluster for macOS](https://github.com/rimusz/coreos-osx-cluster).

## Contributing

**Kube-Cluster for macOS** is an [open source](http://opensource.org/osd) project release under
the [Apache License, Version 2.0](http://opensource.org/licenses/Apache-2.0),
hence contributions and suggestions are gladly welcomed!
