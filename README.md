# Synopsis

KVM VirtualMachine of Xpenology DSM running in a docker container, which can be run directly from docker-hub by specifying a BOOTLOADER_URL or a local file.

This is just a kvm in docker which has been configured (and tested) to run xpenology dsm 6.2.3/7.2.2 with jun and redpill bootloader.
So technically it can run any bootloader you provide.

Latest tested (for DS3615xs):
- 6.2.3 with Jun's 1.03b (virtio+9p)
- 7.2 with rr 24.10 (virtio+9p) from https://github.com/RROrg/rr

UPDATE:
- PID, VID and SN (Serial Number) can now be pass as parameter to Docker, the bootloader is modified during the first boot. (work with Jun's bootloader)
- Redpill bootloader compatibility
- Run without BOOTLOADER_URL by using local file with following docker option: `-v /path/myfile:/bootloader`

## Warning / Disclaimer

This project contains only open-source code and does not distribute any copyrighted material.

This is for testing or educational purpose ONLY, and It is NOT recommended for using in production environment because it has no support, and it has not been proven stable/reliable.

Be aware that, Synology's Virtual DSM end-user license agreement does not permit installation on non-Synology hardware. So comply with this by using Synology hardware. 

DATA LOSS can happen by using this system due to its instability, SO this is ONLY on your own responsibility to use.

If you are happy with the testing of this product, I would highly recommend you to go for an original Synology hardware, especially for PRODUCTION environment where data is critical.

## Repositories / Tutorial

Source code : https://github.com/uxora-com/xpenology-docker

Docker image: https://hub.docker.com/r/uxora/xpenology

Tutorial: https://www.uxora.com/other/virtualization/57-xpenology-on-docker

Compile Redpill bootloader: https://github.com/uxora-com/rpext

NEW: rr bootloader: https://github.com/RROrg/rr

## Testing Notes
Personal testing has been done with ds3615xs jun's loader 1.03b and RedPill (with virtio/9p drivers).

- Proxmox Lxc (OK):
	- Cpu AMD
	- Proxmox 8.2-7
	- Template lxc "debian-10-standard_10.5-1_amd64"
	- dsm 6.2.3/7.0.1-42218 OK, Live snapshot OK, 9p mount OK
	- dsm 7.2.2-72806, Live snapshot OK, 9p mount OK

- MxLinux live usb (OK):
	- Cpu Intel i7
	- Linux Debian 4.19.0-9-amd64
	- dsm 6.2.3/7.0.1-42218 OK, Live snapshot OK, 9p mount OK

- Windows 10 docker (OK but Slow):
	- Intel i7 cpu
	- dsm 6.2.3/7.0.1-42218 OK but very slow for loading bootloader
	- dsm 7.2.2-72806 OK

- Proxmox VM Linux Debian 10 (OK):
	- Nested virtualization all set and validated with virt-host-validate
	- dsm 7.0.1-42218 OK, Live snapshot OK, 9p mount OK
	- dsm 7.2.2-72806 OK, Live snapshot OK, 9p mount OK

If you have any issue, please raise it in "issues" area.


## Features

This image provides some special features to get the VM running as straightforward as possible
- VM NAT (default): NAT + Port Forwarding: "DOCKER_HOST_IP:5000" (port 5000 can be different depends on your ports mapping)
- VM DHCP: DHCP with macvtap: "DHCP_IP:5000" (see Notes section below)
- Live Snapshot: Create and restore (pretty useful to test update)
- 9P Mountpoints (Access host docker volumes from Xpenology)


## Requirements

* Host with vt-x compatibility
* KVM Module installed `modprobe kvm-intel`
* vHost Module installed `modprobe vhost-net`
* Docker installed (>1.10)
* Xpenology bootloader image (virtio and 9p drivers supported)


## Usage

```bash
# Simple run
$ docker run --cap-add=NET_ADMIN --sysctl net.ipv4.ip_forward=1 \
    --device=/dev/net/tun --device=/dev/kvm \
    -p 5000-5001:5000-5001 \
    -e BOOTLOADER_URL="http://example.com/path/synoboot.tgz" \
    uxora/xpenology

# Run with more specific parameters
$ docker run --name="xpenodock" --hostname="xpenodock" \
    --cap-add=NET_ADMIN --sysctl net.ipv4.ip_forward=1 \
    --device=/dev/net/tun --device=/dev/kvm --device=/dev/vhost-net \
    -p 5000-5001:5000-5001 -p 2222:22 -p 8080:80 \
    -p 137-139:137-139 -p 443-445:443-445 -p 6690:6690 \
    -p 7304:7304 -p 7681:7681 \
    -e CPU="qemu64" -e THREADS=1 -e RAM=2048 \
    -e DISK_SIZE="16G 16G" -e DISK_PATH="/xpy/diskvm" \
    -e VM_ENABLE_9P="Y" -e VM_9P_PATH="/xpy/share9p" \
    -e BOOTLOADER_AS_USB="Y" -e VM_ENABLE_VIRTIO="Y" \
    -e BOOTLOADER_URL="http://example.com/path/synoboot.zip" \
    -e GRUBCFG_SATAPORTMAP="6" -e GRUBCFG_DISKIDXMAP="00" \
    -v /host_dir/data:/xpy/share9p -v /host_dir/kvm:/xpy/diskvm \
    uxora/xpenology
```

Note0: For full disk passthrough, check tutorial here: https://www.uxora.com/other/virtualization/57-xpenology-on-docker

Note1: If you do not want to use BOOTLOADER_URL, copy it as "bootloader.img" to DISK_PATH. In our 2nd example, bootloader should be copied to "/host_dir/kvm/bootloader.img".

Note2: After successfully running this container, you will be able to access the DSM WebUI with docker HOST_IP and port 5000 (i.e. 192.168.1.25:5000).

Note3: Log file is stored in `DISK_PATH/log`

## Variables

Multiples environment variables can be modified to alter default runtime.

* CPU: (Default "qemu64") type of cpu
* THREADS: (Default "1") number of cpu threads per core
* CORES: (Default "1") number of cpu cores
* RAM: (Default "2048") number of ram memory in MB


* DISK_SIZE:(Default "16") Size of virtual disk in GB
	* Set DISK_SIZE=0, if you don't want to have a virtual disk
	* Set more values separated by space, to have more virtual disk (i.e. DISK_SIZE="8 16")
	* It is now possible to pass the full disk device  (i.e. DISK_SIZE="8G /dev/sdc")

* DISK_FORMAT: (Default "qcow2") Type of disk format (qcow2 support snapshot), check [here](https://en.wikibooks.org/wiki/QEMU/Images) for more details.
* DISK_OPTS_DRV: (Default "cache=writeback,discard=on,aio=threads,detect-zeroes=on")
	* Additional option for disk drive. check [here](https://en.wikibooks.org/wiki/QEMU/Devices/Storage) for more details.
* DISK_OPTS_DEV: (Default "rotation_rate=1")
	* Additional option for disk device. check [here](https://en.wikibooks.org/wiki/QEMU/Devices/Storage) for more details.
* DISK_PATH: (Default "/xpy/diskvm") Directory path where disk image (and bootloader) will be stored


* BOOTLOADER_URL: (Default "") URL web link of the bootloader (i.e. "http://host/path/bootloader.img")
	* It can be raw, zip, gzip or tgz file.
	* If "bootloader.img" file already exists in DISK_PATH, then it skips BOOTLOADER_URL download.
	* If using docker option: `-v /path/myfile:/bootloader` , then it skips BOOTLOADER_URL download.
* BOOTLOADER_AS_USB: (Default "Y") Boot the bootloader as USB or as Disk
* BOOTLOADER_FORCE_REPLACE: Remove existing bootloader in DISK_PATH before getting bootloader.

* VM_NET_IP: (Default "20.20.20.21") Assigned IP for VM DHCP. Don't need to be changed. 
* VM_NET_MAC: (Default "00:11:32:2C:A7:85") Mac address use for VM DHCP to assigne VM_NET_IP. This need to match MAC set in xpenology grub bootloader. 


* VM_ENABLE_VGA: (Default "Yes") Enabling qxl vga and vnc. Not needed for Xpenology.
* VM_ENABLE_VIRTIO: (Default "Yes") Enabling virtio disk. Make sure that bootloader has virtio drivers.
* VM_ENABLE_VIRTIO_SCSI: (Default "No") Enabling virtio scsi disk. Make sure that bootloader has virtio drivers.
	* VM_ENABLE_VIRTIO auto enabled.
	* Use "S" value for Virtio SCSI Single.


* VM_ENABLE_9P: (Default "No") Enabling virtio 9p mount point. Need VM_ENABLE_VIRTIO enabled.
* VM_9P_PATH: (Default "") Directories path of 9p mount point to be shared with xpenology
	* VM_ENABLE_9P auto enabled
	* Can set multiple values separated by space (i.e. -e VM_9P_PATH="/xpy/share9p /xpy/diskvm")
	* For each value, it will be associated to 9p mount point tag "hostdata0", "hostdata1", ...
	* Use with -v docker option for each value (i.e. -v /host_dir/data:/xpy/share9p)
* VM_9P_OPTS: (Default "local,security_model=passthrough") 9p fsdev options. Check [here](https://wiki.qemu.org/Documentation/9psetup) for more details.

* VM_CUSTOM_OPTS: (Default "") Additional custom option to add to qemu command line
* VM_CUSTOM_CODE: (Default "") Additional custom code to add before qemu command line


* VM_TIMEOUT_POWERDOWN: (Default "30") Timeout for vm-power-down command


* GRUBCFG_ENABLE_MOD: (Default "N") Auto set GRUBCFG_VID/GRUBCFG_PID if empty, depending on BOOTLOADER_AS_USB value. (Not needed for RR bootloader)
* GRUBCFG_VID: (Default "") VendorID of bootloader disk.
* GRUBCFG_PID: (Default "") ProductID of bootloader disk.
* GRUBCFG_SN: (Default "") Serial number of DSM.

* GRUBCFG_SATAPORTMAP: (Default "") Each digit is the number of port of a sata device (ie "6") 
* GRUBCFG_DISKIDXMAP: (Default "") 2 digits to map each sata device (ie "00")
* GRUBCFG_HDDHOTPLUG: (Default "") Not used yet ...


## Featured Functions
The container has extra defined functions which allow you to manipulate the running VM:
- vm-power-down: This function Shutdown graceful the VM, until VM_TIMEOUT_POWERDOWN variable is reached.
- vm-power-reset: Hard Reset the VM (this function doesn't stop the container)
- vm-snap-create "snapshotName": Create a Live snapshot with memory (work with DISK_FORMAT=qcow2)
- vm-snap-delete "snapshotName": Delete a Live snapshot
- vm-snap-restore "snapshotName": stop the VM and restart using the chosen snapshot
- vm-snap-info: Show all the snapshots
- vm-cmd "command": Send command to qemu monitor, check [here](https://www.qemu.org/docs/master/system/monitor.html) for more details.

Example:
```bash
$ docker exec $( docker container ls -f 'ancestor=uxora/xpenology' -f "status=running" -q ) vm-snap-create bckBeforeUpd
$ docker exec xpenodock vm-snap-restore bckBeforeUpd
```


## Notes

### Build docker image

If you want to make some code changes of your own.

```bash
$ git clone https://github.com/uxora-com/xpenology-docker.git
$ cd xpenology-docker
$ # Make all your personal changed
$ docker build -t uxora/xpenology .
```

### Xpenology bootloader

You need xpenology bootloader image with virtio drivers for better compatibility.

Check [this forum](https://xpenology.com/forum/) for more details about xpenology bootloader.

And follow [this tutorial](https://xpenology.club/compile-drivers-xpenology-with-windows-10-and-build-in-bash) if you want to compile drivers for your specific xpenology version.
(RR bootloader already include a lot of module and drivers, so you probably does not need that with RR bootloader)

If you use RR bootloader, you may want to check this tutorial before: https://xpenology.com/forum/topic/69718-tuto-dsm-7-pour-tous/ 

### Running docker without BOOTLOADER_URL

```bash
# Run xpenology docker (Warning: fake SN which need to be changed)
$ docker run --name="xpenodock" --hostname="xpenodock" \
    --cap-add=NET_ADMIN --sysctl net.ipv4.ip_forward=1 \
    --device=/dev/net/tun --device=/dev/kvm \
    -p 5000-5001:5000-5001 -p 2222:22 -p 8080:80 \
    -p 137-139:137-139 -p 443-445:443-445 -p 6690:6690 \
    -p 7304:7304 -p 7681:7681 \
    -e RAM="1024" -e DISK_SIZE="16G" \
    -e GRUBCFG_SN="1234ABC012345" \
    -e GRUBCFG_SATAPORTMAP="6" -e GRUBCFG_DISKIDXMAP="00" \
    -e DISK_PATH="/xpy/diskvm" -e VM_9P_PATH="/xpy/share9p" \
    -v /host_dir/kvm:/xpy/diskvm -v /host_dir/data:/xpy/share9p \
    -v /local_path/synoboot.tgz:/bootloader \
    uxora/xpenology
```

### Running docker with its own fixed IP (No port mapping needed)

```bash
# On docker host
# Create a macvlan matching your local network
$ docker network create -d macvlan \
    --subnet=192.168.0.0/24 \
    --gateway=192.168.0.1 \
    --ip-range=192.168.0.96/28 \
    -o parent=eth0 \
    macvlan0

# Run xpenology docker (Warning: fake SN/URL which need to be changed)
$ docker run --name="xpenodock" --hostname="xpenodock" \
    --cap-add=NET_ADMIN --sysctl net.ipv4.ip_forward=1 \
    --device=/dev/net/tun --device=/dev/kvm \
    --network macvlan0 --ip=192.168.0.100 \
    -e BOOTLOADER_URL="https://github.com/RROrg/rr/releases/download/24.10.0/rr-24.10.0.img.zip" \
    -e RAM="2048" -e DISK_SIZE="32G" \
    -e DISK_PATH="/xpy/diskvm" -e VM_9P_PATH="/xpy/share9p" \
    -v /host_dir/kvm:/xpy/diskvm -v /host_dir/data:/xpy/share9p \
    uxora/xpenology
```

### Running docker with DHCP IP (No port mapping needed)
```bash
# On docker host
# Create a macvlan matching your local network
$ docker network create -d macvlan \
    --subnet=192.168.0.0/24 \
    --gateway=192.168.0.1 \
    --ip-range=192.168.0.96/28 \
    -o parent=eth0 \
    macvlan0

# Run xpenology docker (Warning: --device-cgroup-rule number may be different for you)
$ docker run --name="xpenodock" --hostname="xpenodock" \
    --cap-add=NET_ADMIN --device-cgroup-rule='c 239:* rwm' \
    --device=/dev/net/tun --device=/dev/kvm --device=/dev/vhost-net \
    --network macvlan0 -e VM_NET_DHCP="Y" \
    -e BOOTLOADER_URL="https://github.com/RROrg/rr/releases/download/24.10.0/rr-24.10.0.img.zip" \
    -e RAM="2048" -e DISK_SIZE="32G" \
    -e DISK_PATH="/xpy/diskvm" -e VM_9P_PATH="/xpy/share9p" \
    -v /host_dir/kvm:/xpy/diskvm -v /host_dir/data:/xpy/share9p \
    uxora/xpenology
```

### Some useful docker command

```bash
# Access container by name
$ docker exec -ti xpenodock /bin/bash

# Access container in another way
$ docker exec -ti $( docker container ls -f 'ancestor=uxora/xpenology' -f "status=running" -q ) /bin/bash

# Stop and Delete containers
$ docker container stop xpenodock && docker container rm xpenodock

# Delete docker image
$ docker rmi $( docker image ls --filter 'reference=uxora/*' -q )
```

### Mount Docker Host Volumes to Xpenology

Open a ssh terminal on your xpenology dsm:

```bash
# Load 9p drivers, if not already loaded
$ sudo insmod /volume1/homes/admin/9pnet.ko
$ sudo insmod /volume1/homes/admin/9pnet_virtio.ko
$ sudo insmod /volume1/homes/admin/9p.ko

# In DSM web gui, create a "new share folder" in File Station (i.e. datashare9p)
# then mount 9p hostdata0 to this folder  
$ sudo mount -t 9p -o trans=virtio,version=9p2000.L,msize=262144 hostdata0 /volume1/datashare9p
$ sudo chown -R :users /volume1/datashare9p
$ sudo chmod -R g+rw /volume1/datashare9p
```

Check https://www.kernel.org/doc/Documentation/filesystems/9p.txt for 9p mount options (and set VM_9P_OPTS that suit you the best).
	
If you want automount 9p folder at boot time, use "Control Panel > Task Scheduler > Create > Triggered Task" to set this command line as root schedule task.

### SAMBA
Make sure to forward SMB ports on docker command line by adding `-p 137-139:137-139 -p 445:445`.
Then access it by `\\HOST_IP`.
If you want to access by name, you will have to add it on `hosts` file of your machine.

### Changing container parameters
CAUTION: Most important files are vm disks. As long as you keep it safe, you should be able to get back your xpenology.
* If you used `-v` option to mount host directory to `DISK_PATH` as `-e DISK_PATH="/xpy/diskvm" -v /host_dir/kvm:/xpy/diskvm`
	- You should get all your bootloader and vm disks in /host_dir/kvm
* If you didn't use -v option, then it uses docker volume on `DISK_PATH`
	- You should find bootloader and kvm disks on a directory like : `/var/lib/docker/volumes/[...]/_data/` 

If you need to change a bootloader parameter (VM_NET_MAC and GRUBCFG_*):
- In DISK_PATH (i.e. `/host_dir/kvm`) folder, uncompress : `$ tar -xzf bootloader.img.tar.gz`
- Then delete: `$ rm bootloader.img.tar.gz bootloader.qcow2`
- Then follow instructions below for others parameters

Otherwise, for all others parameters :
- Delete or Rename your old container: `$ docker container rm $( docker container ls -qf 'ancestor=uxora/xpenology' )`
- Then recreate a container with new parameters: `$ docker run [...]`

## Troubleshooting

* Normally privileged mode (`--privileged`) is not needed, but you may try it to see if it does not work on your system.
	
#### If you get the following error from KVM:
```
qemu-kvm: -netdev tap,id=net0,vhost=on,fd=3: vhost-net requested but could not be initialized
  
qemu-kvm: -netdev tap,id=net0,vhost=on,fd=3: Device 'tap' could not be initialized
```

* you will need to load the `vhost-net` kernel module in your dockerhost (as root) prior to launch this container:
```bash
$ modprobe vhost-net
```

	
#### Sometimes on start the VM some random errors appear(I don't know why yet)
```
cpage out of range (5)
processing error - resetting ehci HC
```
* If this happens to you, reboot the container

	
#### If you have permission issue with /dev/kvm or /dev/net/tun, give other +rw permission in host
```bash
$ chmod o+rw /dev/kvm
$ chmod o+rw /dev/net/tun
```


#### If you have fuse issue
```bash
$ modprobe fuse
# or # $ apt-get reinstall fuse
```


#### if iptables issue with msg like:
```
    iptables v1.6.0: can't initialize iptables table `nat': Table does not exist (do you need to insmod?)
    Perhaps iptables or your kernel needs to be upgraded.
```

* Try to reload ip_tables module
```bash
$ modprobe ip_tables
```

#### If you have corrupt file (13) during dsm installation
	- Make sure you have set the right GRUBCFG_VID, GRUBCFG_PID and GRUBCFG_SN.

#### Something went wrong (hard drives and SATA ports)
With the following message
```
We've detected errors on the hard drive (x, y) and the SATA ports have also been disabled.
```
* Then try to add these bootloader parameters: `-e GRUBCFG_SATAPORTMAP="6" -e GRUBCFG_DISKIDXMAP="00"`
* This required to delete current bootloader to be able to rebuilt it
* Try to change to other value if this one does not work  

## License
Licensed to the Apache Software Foundation (ASF) under one or more contributor license agreements. See the NOTICE file distributed with this work for additional information regarding copyright ownership. The ASF licenses this file to you under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

## Contributors
Michel VONGVILAY ([www.uxora.com](https://www.uxora.com/about/me#contact-form))

Project based on :
* Isaac Aymerich - [segator/xpenology-docker](https://github.com/segator/xpenology-docker)
* BBVA Innotech - [BBVA/kvm](https://github.com/BBVA/kvm)
