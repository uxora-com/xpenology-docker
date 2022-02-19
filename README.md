# Synopsis

KVM VirtualMachine of Xpenology DSM running in a docker container, which can be run directly from docker-hub by specifying a BOOTLOADER_URL.

This is just a kvm in docker which has been configured (and tested) to run xpenology dsm 6.2.3/7.0.1 with jun and redpill bootloader.
So technicaly it can run any bootloader you provide.

Latest tested (dor DS3615xs):
- 6.2.3 with Jun's 1.03b (virtio+9p)
- 7.0.1 with redpill (virtio+9p)

UPDATE:
- PID, VID and SN (Serial Number) can now be pass as parameter to Docker, the bootloader is modified during the first boot.
- Redpill bootloader compatibility

## Warning / Disclaimer

This system is for testing or educational purpose ONLY, and It is NOT recommended for using in production environment because it has no support and it has not been proven  stable/reliable.

So DATA LOSS can happens by using this system due to its instability, SO this is ONLY on your own responsibility to use.

If you are happy with the testing of this product, I would highly recommend you to go for an original Synology hardware especially for PRODUCTION environment where data is critical.

## Repositories / Tutorial

Source code : https://github.com/uxora-com/xpenology-docker

Docker image: https://hub.docker.com/r/uxora/xpenology

Tutorial: https://www.uxora.com/other/virtualization/57-xpenology-on-docker

Compile Redpill bootloader: https://github.com/uxora-com/rpext

## Testing Notes
Personnal testing has been done with ds3615xs jun's loader 1.03b with virtio drivers.

- Proxmox Lxc (OK):
	- Cpu AMD
	- Proxmox 6.4-13 Kernel 5.4.140-1-pve
	- Template lxc "debian-10-standard_10.5-1_amd64"
	- dsm 6.2.3/7.0.1-42218 OK, Live snapshot OK, 9p mount OK

- MxLinux live usb (OK):
	- Cpu Intel i7
	- Linux Debian 4.19.0-9-amd64
	- dsm 6.2.3/7.0.1-42218 OK, Live snapshot OK, 9p mount OK

- Windows 10 docker (OK but Slow):
	- Intel i7 cpu
	- dsm 6.2.3/7.0.1-42218 OK but very slow for loading bootloader

- Proxmox VM Linux Debian 10 (OK):
	- Nested virtualization all set and validated with virt-host-validate
	- dsm 7.0.1-42218 OK, Live snapshot OK, 9p mount OK

If you have any issue, please raise it in "issues" area.


## Features

This image provides some special features to get the VM running as straightforward as possible
- VM DHCP: Runing VM will have DHCP and will be provisioned with 20.20.20.21 (by default)
- Port Forwarding From container to VM, in order to access to the VM using the HOST_IP:5000
- Live Snapshoting: Create and restore (pretty useful to test update)
- 9P Mountpoints (Access host docker volumes from Xpenology)


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
	-e BOOTLOADER_URL="http://example.com/path/synoboot.tgz" \
	uxora/xpenology

# Run with more specific parameters
$ docker run --name="xpenodock" --hostname="xpenodock" \
	--privileged --cap-add=NET_ADMIN \
	--device=/dev/net/tun --device=/dev/kvm \
	-p 5000-5001:5000-5001 -p 2222:22 -p 8080:80 \
	-e CPU="qemu64" -e THREADS=1 -e RAM=512 \
	-e DISK_SIZE="8G 16G" -e DISK_PATH="/xpy/diskvm" \
	-e VM_ENABLE_9P="Y" -e VM_PATH_9P="/xpy/share9p" \
	-e BOOTLOADER_AS_USB="Y" -e VM_ENABLE_VIRTIO="Y" \
	-e BOOTLOADER_URL="http://192.168.0.14/path/synoboot.zip" \
	-e GRUBCFG_DISKIDXMAP="00" -e GRUBCFG_SATAPORTMAP="2" \
	-v /host_dir/data:/xpy/share9p \
	-v /host_dir/kvm:/xpy/diskvm \
	uxora/xpenology
```

Note0: For full disk passtrough, check tutorial here: https://www.uxora.com/other/virtualization/57-xpenology-on-docker

Note1: If you do not want to use BOOTLOADER_URL, copy it as "bootloader.img" to DISK_PATH. In our 2nd example, bootloader should be copied to "/host_dir/kvm/bootloader.img".

Note2: After successfully running this container, you will be able to access the DSM WebUI with docker HOST_IP and port 5000 (ie. 192.168.1.25:5000).

Note3: Log file is stored in `DISK_PATH/log`

## Variables

Multiples environment variables can be modified to alter default runtime.

* CPU: (Default "qemu64") type of cpu
* THREADS: (Default "1") number of cpu threads per core
* CORES: (Default "1") number of cpu cores
* RAM: (Default "512") number of ram memory in MB


* DISK_SIZE:(Default "16") Size of virtual disk in GB
	* Set DISK_SIZE=0, if you don't want to have a virtual disk
	* Set more values separated by space, to have more virtual disk (ie. DISK_SIZE="8 16")
	* It is now possible to pass the full disk device  (ie. DISK_SIZE="8G /dev/sdc")

* DISK_FORMAT: (Default "qcow2") Type of disk format (qcow2 support snapshot), check [here](https://en.wikibooks.org/wiki/QEMU/Images) for more details.
* DISK_CACHE: (DEPRECATED) Replace by DISK_OPTS_DRV.
* DISK_OPTS_DRV: (Default "cache=writeback,discard=on,aio=threads,detect-zeroes=on")
	* Additional option for disk drive. check [here](https://en.wikibooks.org/wiki/QEMU/Devices/Storage) for more details.
* DISK_OPTS_DEV: (Default "rotation_rate=1")
	* Additional option for disk device. check [here](https://en.wikibooks.org/wiki/QEMU/Devices/Storage) for more details.
* DISK_PATH: (Default "/xpy/diskvm") Directory path where disk image (and bootloader) will be stored


* BOOTLOADER_URL: (Default "") URL web link of the bootloader (ie. "http://host/path/bootloader.img")
	* It can be raw, zip, gzip or tgz file.
	* If "bootloader.img" file already exists in DISK_PATH, then it skips BOOTLOADER_URL download.
* BOOTLOADER_AS_USB: (Default "Y") Boot the bootloader as USB or as Disk


* VM_IP: (Default "20.20.20.21") Assigned IP for VM DHCP. Don't need to be changed. 
* VM_MAC: (Default "00:11:32:2C:A7:85") Mac address use for VM DHCP to assigne VM_IP. This need to match MAC set in xpenology grub bootloader. 


* VM_ENABLE_VGA: (Default "No") Enabling qxl vga and vnc. Not needed for Xpenology.
* VM_ENABLE_VIRTIO: (Default "Yes") Enabling virtio disk. Make sure that bootloader has virtio drivers.
* VM_ENABLE_VIRTIO_SCSI: (Default "No") Enabling virtio scsi disk. Make sure that bootloader has virtio drivers.
	* VM_ENABLE_VIRTIO auto enabled.
	* Use "S" value for Virtio SCSI Single.


* VM_ENABLE_9P: (Default "No") Enabling virtio 9p mount point. Need VM_ENABLE_VIRTIO enabled.
* VM_9P_PATH: (Default "") Directories path of 9p mount point to be shared with xpenology
	* VM_ENABLE_9P auto enabled
	* Can set multiple values separated by space (ie. -e VM_PATH_9P="/xpy/share9p /xpy/diskvm")
	* For each value, it will be associated to 9p mount point tag "hostdata0", "hostdata1", ...
	* Use with -v docker option for each value (ie. -v /host_dir/data:/xpy/share9p)
* VM_9P_OPTS: (Default "local,security_model=passthrough") 9p fsdev options. 
* VM_CUSTOM_OPTS: (Default "") Additionnal custom option to add to the launcher qemu command line

* VM_TIMEOUT_POWERDOWN: (Default "30") Timeout for vm-power-down command


* GRUBCFG_AUTO: (Default "Y") Auto set GRUBCFG_VID/GRUBCFG_PID if empty, depending on BOOTLOADER_AS_USB value.
* GRUBCFG_VID: (Default "") VendorID of bootloader disk.
* GRUBCFG_PID: (Default "") ProductID of bootloader disk.
* GRUBCFG_SN: (Default "") Serial number of DSM.


* GRUBCFG_DISKIDXMAP: (Default "")
* GRUBCFG_SATAPORTMAP: (Default "")
* GRUBCFG_HDDHOTPLUG: (Default "")


## Featured Functions
The container has extra defined functions which allow you to manipulate the running VM:
- vm-power-down: This function Shutdown graceful the VM, until VM_TIMEOUT_POWERDOWN variable is reached.
- vm-power-reset: Hard Reset the VM (this function doesn't stop the container)
- vm-snap-create <snapshotName>: Create a Live snapshot with memory (work with DISK_FORMAT=qcow2)
- vm-snap-delete <snapshotName>: Delete a Live snapshot
- vm-snap-restore <snapshotName>: stop the VM and restart using the choosed snapshot
- vm-snap-info: Show all the snapshots
- vm-cmd <command>: Send command to qemu monitor, check [here](https://www.qemu.org/docs/master/system/monitor.html) for more details.

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
$ docker build -t uxora/xpenology .
```

### Xpenology bootloader

You need xpenology bootloader image with virtio drivers for better compatibility.

Check [this forum](https://xpenology.com/forum/) for more details about xpenology bootloader.

And follow [this tutorial](https://xpenology.club/compile-drivers-xpenology-with-windows-10-and-build-in-bash) if you want to compile drivers for your specific xpenology version.

### Recommended setup (without BOOTLOADER_URL)

```bash
# Copy bootloader
$ cp synoboot_103b_ds3615xs_virtio_9p.img /host_dir/kvm/bootloader.img

# Run xpenology docker (Warning: fake SN which need to be changed)
$ docker run --name="xpenodock" --hostname="xpenodock" \
    --privileged --cap-add=NET_ADMIN \
    --device=/dev/net/tun --device=/dev/kvm \
    -p 5000-5001:5000-5001 -p 2222:22 -p 8080:80 \
    -p 137-139:137-139 -p 445:445 \
    -e RAM="512" -e DISK_SIZE="16G" \
    -e GRUBCFG_SN="1234ABC012345" \
    -e GRUBCFG_DISKIDXMAP="00" -e GRUBCFG_SATAPORTMAP="2" \
    -e DISK_PATH="/xpy/diskvm" -e VM_PATH_9P="/xpy/share9p" \
    -v /host_dir/kvm:/xpy/diskvm -v /host_dir/data:/xpy/share9p \
    uxora/xpenology
```

### Mount Docker Host Volumes to Xpenology

To mount Host Path/Docker Volumes to your Xpenology Image, you need to load 9p drivers in your xpenology image.

After having your image with 9p drivers loaded, you need to create and script that will executed on every boot in your xpenology.
This script should load the drivers and mount your 9p mountpoint, by default this docker image map the path `/xpy/share9p` to the 9p `hostdata0`.

Example
```bash
# Load 9p drivers, if not already loaded
$ sudo insmod /volume1/homes/admin/9pnet.ko
$ sudo insmod /volume1/homes/admin/9pnet_virtio.ko
$ sudo insmod /volume1/homes/admin/9p.ko

# From DSM web gui, create a "new share folder" in File Station (ie. datashare9p)
# Open a ssh terminal on xpenology, then mount 9p hostdata0 to this folder  
$ sudo mount -t 9p -o trans=virtio,version=9p2000.L,msize=262144 hostdata0 /volume1/datashare9p
$ sudo chown -R :users /volume1/datashare9p
$ sudo chmod -R g+rw /volume1/datashare9p
```

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
```

If you need to change a bootloader parameter (VM_MAC and GRUBCFG_*):
- In DISK_PATH (ie. `/host_dir/kvm`) folder, uncompress : `$ tar -xzf bootloader.img.tar.gz`
- Then delete: `$ rm bootloader.img.tar.gz bootloader.qcow2`
- Then follow instructions below for others parameters

Otherwise for all others parameters :
- Delete or Rename your old container: `$ docker container rm $( docker container ls -qf 'ancestor=uxora/xpenology' )`
- Then recreate a container with new parameters: `$ docker run --privileged [...]`

## TroubleShooting

* Privileged mode (`--privileged`) is needed in order for KVM to access to macvtap devices
	
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
* If this happen to you simple reboot the container

	
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
* Then try to add these bootloader parameters: `-e GRUBCFG_DISKIDXMAP="00" -e GRUBCFG_SATAPORTMAP="2"`
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

## Want to buy me a coffee
* ERC20/BEP20 : 0xD861bc743495b2f1b00Cd420092d548833369756
* BTC: bc1qzjg4t55ljcr3vmdegh2c85xgejk89xqw0m3pxc
