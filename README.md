# Synopsis

KVM VirtualMachine of Xpenology dsm (6.2.3:latest tested) running in a docker container, which can be run directly from docker-hub by specifying a BOOTLOADER_URL.

This is just a kvm in docker which has been configured (and tested) to run xpenology dsm 6.2.3 with jun's xpenology bootloader.
So technicaly it can run any bootloader you provide.

The project is based on [segator/xpenology-docker](https://github.com/segator/xpenology-docker) project which is based on [BBVA/kvm](https://github.com/BBVA/kvm) project.

## Repositories

Source code : https://github.com/uxora-com/xpenology-docker

Docker image: https://hub.docker.com/r/uxora/xpenology

## Testing Notes
Personnal testing has been done with ds3615xs jun's loader 1.03b with virtio drivers.

- Proxmox Lxc (OK):
	- Cpu AMD
	- Proxmox 6.2-11 Kernel 5.4.60-1-pve
	- Template lxc "debian-10-standard_10.5-1_amd64"
	- dsm 6.2.3 OK, Live snapshot OK, 9p mount OK

- MxLinux live usb (OK):
	- Cpu Intel i7
	- Linux Debian 4.19.0-9-amd64
	- dsm 6.2.3 OK, Live snapshot OK, 9p mount OK

- Windows 10 docker (OK but Slow):
	- Intel i7 cpu
	- dsm 6.2.3 OK but very slow for loading bootloader, Snapshot and 9p not tested

- Proxmox VM Linux Debian 10 (NOT working):
	- Nested virtualization all set and validated with virt-host-validate
	- After grub boot menu, it's black screen or sometime mount error
	- I don't know why it doesn't work, any idea?

If you have any issue, please raise it in "issues" area.

## Features

This image provides some special features to get the VM running as straightforward as possible
- VM DHCP: Runing VM will have DHCP and will be provisioned with 20.20.20.21 (by default)
- Port Forwarding From container to VM, in order to access to the VM using the container IP
- Live Snapshoting
- 9P Mountpoints (Access docker volumes from Xpenology)


## Requirements

* Host with vt-x compatibility
* KVM Module installed `modprobe kvm-intel`
* vHost Module installed `modprobe vhost-net`
* Docker installed (>1.10)
* Xpenology bootloader image (virtio and 9p drivers supported)


## Usage

`--privileged` parameter always mandatory, here's some examples:

```bash
# Simple run
$ docker run --privileged \
	-e BOOTLOADER_URL="http://example.com/path/synoboot.img" \
	uxora/xpenology

# Run with more specific parameters
$ docker run --privileged --cap-add=NET_ADMIN \
	--device=/dev/net/tun --device=/dev/kvm \
	-p 5000:5000 -p 5001:5001 -p 2222:22 -p 8080:80 \
	-e CPU="qemu64" \
	-e THREADS=1 \
	-e RAM=512 \
	-e DISK_SIZE="8G 16G" \
	-e DISK_PATH="/image" \
	-e BOOTLOADER_URL="http://example.com/path/synoboot.img" \
	-e BOOTLOADER_AS_USB="Y" \
	-e VM_ENABLE_VIRTIO="Y" \
	-v /shared/data:/datashare \
	uxora/xpenology
```


## Variables

Multiples environment variables can be modified to alter default runtime.
* CPU: (Default "qemu64") type of cpu
* THREADS: (Default "1") number of cpu threads per core
* CORES: (Default "1") number of cpu cores
* RAM: (Default "512") number of ram memory in MB

* DISK_SIZE:(Default "16") Size of virtual disk in GB
	* Set DISK_SIZE=0, if you don't want to have a virtual disk
	* Set more values separated by space, to have more virtual disk (ie. DISK_SIZE="8 16")

* DISK_FORMAT: (default "qcow2") Type of disk format (qcow2 support snapshot), check [here](https://en.wikibooks.org/wiki/QEMU/Images) for more details.
* DISK_CACHE: (Default "none") Type of QEMU HDD Cache, check [here](https://en.wikibooks.org/wiki/QEMU/Devices/Storage) for more details
* DISK_PATH: (Default "/image") Directory path where disk image (and bootloader) will be stored

* BOOTLOADER_URL: (Default "") URL web link of the bootloader (ie. "http://host/path/bootloader.img")
* BOOTLOADER_AS_USB: (Default "Y") Boot the bootloader as USB or as Disk

* VM_IP: (Default "20.20.20.21") Assigned IP for VM DHCP. Don't need to be changed. 
* VM_MAC: (Default "00:11:32:2C:A7:85") Mac address use for VM DHCP to assigne VM_IP. This need to match MAC set in xpenology grub bootloader. 

* VM_ENABLE_VGA: (Default "No") Enabling qxl vga and vnc. Not needed for Xpenology.
* VM_ENABLE_VIRTIO: (Default "Yes") Enabling virtio drivers. Make sure that synoboot has virtio drivers.
* VM_ENABLE_9P: (Default "Yes") Enabling virtio 9p mount point. Need VM_ENABLE_VIRTIO enabled.
* VM_PATH_9P: (Default "/datashare") Directory path of 9p mount point to be shared with xpenology. (Usually combined with -v docker option)
* VM_CUSTOM_OPTS: (Default "") Additionnal custom option to add to the launcher qemu command line

* VM_TIMEOUT_POWERDOWN: (Default "10") Timeout for vm-powerdown command

## Featured Functions
The container has extra defined functions which allow you to manipulate the running VM:
- vm-powerdown: This function Shutdown graceful the VM, until VM_TIMEOUT_POWERDOWN variable is reached.
- vm-reset: Hard Reset the VM (this function doesn't stop the container)
- vm-snap-create <snapshotName>: Create a Live snapshot with memory (work with qcow2 and bootloader is exclude)
- vm-snap-delete <snapshotName>: Delete a Live snapshot
- vm-snap-restore <snapshotName>: stop the VM and restart using the choosed snapshot
- vm-snap-info: Show all the snapshots
- vm-cmd <command>: Send command to qemu monitor, check [here](https://www.qemu.org/docs/master/system/monitor.html) for more details.

Example:
```bash
$ docker exec -ti $( docker container ls -f 'ancestor=uxora/xpenology' -f "status=running" -q ) vm-snap-create
```


## Notes

### Xpenology bootloader

You need xpenology bootloader image with virtio drivers for better compatibility.

Check [this forum](https://xpenology.com/forum/) for more details about xpenology bootloader.

And follow [this tutorial](https://xpenology.club/compile-drivers-xpenology-with-windows-10-and-build-in-bash) if you want to compile drivers for your specific xpenology version.


### Mount Docker Host Volumes to Xpenology

To mount Host Path/Docker Volumes to your Xpenology Image, you need to load 9p drivers in your xpenology image.

After having your image with 9p drivers loaded, you need to create and script that will executed on every boot in your xpenology.
This script should load the drivers and mount your 9p mountpoint, by default this docker image map the path /datashare to the 9p "hostdata".

Example
```bash
# Load 9p drivers, if not already loaded
$ sudo insmod /volume1/homes/admin/9pnet.ko
$ sudo insmod /volume1/homes/admin/9pnet_virtio.ko
$ sudo insmod /volume1/homes/admin/9p.ko

#Create a new share folder in DSM (ie. datashare)
#Then mount 9p hostdata to this folder in ssh terminal on xpenology vm
$ sudo mount -t 9p -o trans=virtio,version=9p2000.L,msize=262144 hostdata /volume1/datashare
```


### Build docker image

```bash
$ git clone https://github.com/uxora-com/xpenology-docker.git
$ cd xpenology-docker
$ docker build -t uxora/xpenology .
```

## TroubleShooting

* Privileged mode (`--privileged`) is needed in order for KVM to access to macvtap devices

* If you get the following error from KVM:

```
qemu-kvm: -netdev tap,id=net0,vhost=on,fd=3: vhost-net requested but could not be initialized
  
qemu-kvm: -netdev tap,id=net0,vhost=on,fd=3: Device 'tap' could not be initialized
```

you will need to load the `vhost-net` kernel module in your dockerhost (as root) prior to launch this container:
  
```bash 
$ modprobe vhost-net
```

Sometimes on start the VM some random errors appear(I don't know why yet) 
```
cpage out of range (5)
processing error - resetting ehci HC
```
If this happen to you simple reboot the container

* If you have permission issue with /dev/kvm or /dev/net/tun, give other +rw permission in host
```bash
$ chmod o+rw /dev/kvm
$ chmod o+rw /dev/net/tun
```
* If you have fuse issue
```bash
$ modprobe fuse
# or # $ apt-get reinstall fuse
```

* if iptables issue with msg like:
```
	iptables v1.6.0: can't initialize iptables table `nat': Table does not exist (do you need to insmod?)
	Perhaps iptables or your kernel needs to be upgraded.
```

Try to reload ip_tables module
```bash
$ modprobe ip_tables
```

## License
Licensed to the Apache Software Foundation (ASF) under one or more contributor license agreements. See the NOTICE file distributed with this work for additional information regarding copyright ownership. The ASF licenses this file to you under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

## Contributors
Michel VONGVILAY ([www.uxora.com](https://www.uxora.com/about/me#contact-form))

Based on project of : Isaac Aymerich and BBVA Innotech
