# Vagrant

Installation instructions for **Ubuntu**. This document has also been written by [@pedronofuentes](https://github.com/pedronofuentes).

## Installation

- Download and install vagrant
- Download and install VirtualBox
- Go to the puphpet site and create a new vagrant file or download this.
- Execute `vagrant up` in the downloaded directory
- Execute `vagrant ssh` to enter your new machine


## Issues

#### PROBLEM 1

```
3SLPJm ➤ vagrant up
VirtualBox is complaining that the kernel module is not loaded. Please
run `VBoxManage --version` or open the VirtualBox GUI to see the error
message which should contain instructions on how to fix this error.

3SLPJm ➤ VBoxManage --version
WARNING: The vboxdrv kernel module is not loaded. Either there is no module
         available for the current kernel (3.11.0-13-generic) or it failed to
         load. Please recompile the kernel module and install it by

           sudo /etc/init.d/vboxdrv setup

         You will not be able to start VMs until this problem is fixed.
```

**SOLUTION:**

```
sudo apt-get install linux-headers-3.11.0-13-generic
sudo /etc/init.d/vboxdrv setup
```



#### PROBLEM 2

```
3SLPJm ➤ vagrant up
[default] Waiting for machine to boot. This may take a few minutes...
The guest machine entered an invalid state while waiting for it
to boot. Valid states are 'starting, running'. The machine is in the
'poweroff' state. Please verify everything is configured
properly and try again.

If the provider you're using has a GUI that comes with it,
it is often helpful to open that and watch the machine, since the
GUI often has more helpful error messages than Vagrant can retrieve.
For example, if you're using VirtualBox, run `vagrant up` while the
VirtualBox GUI is open.
```


**SOLUTION:**

Enable VT-X virtualization in BIOS

```
$ sudo apt-get install virtualbox-dkms
$ sudo dpkg-reconfigure virtualbox
```


#### PROBLEM 3
VirtualBox complains about not having _Guest additions_.

**SOLUTION:**

```
$ vagrant plugin install vagrant-vbguest
```



#### PROBLEM 4

Provisions are not installed.

**SOLUTION:**

```
$ vagrant provision
```


#### PROBLEM 5

VirtualBox does not start the machine after a distribution update.

**SOLUTION:**

```
$ sudo apt-get install linux-headers-generic
$ sudo dpkg-reconfigure virtualbox
```


#### PROBLEM 6

Having installed the vagrant-vbguest plugin, it provisions everything ok in a machine, but it does not in another based in CentOS (Puphpet).

**SOLUTION:**

Add `config.vbguest.auto_update = false` to the Vagrant file.

