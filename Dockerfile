FROM uxora/linux-kvm:oracular
LABEL maintainer="Michel VONGVILAY <https://www.uxora.com/about/me#contact-form>"
LABEL version="0.93"


ENV SCRIPT_VERSION="0.93"

# Ressources
ENV CPU="qemu64"
ENV THREADS="1"
ENV CORES="1"
ENV RAM="2048"

#Bootloader
ENV BOOTLOADER_URL=""
ENV BOOTLOADER_AS_USB="Y"
ENV BOOTLOADER_FORCE_REPLACE="N"
ENV BOOTLOADER_ALT_PATH="/bootloader"

#Disk
ENV DISK_SIZE="32"
ENV DISK_FORMAT="qcow2"
ENV DISK_OPTS_DRV="cache=writeback,discard=on,aio=threads,detect-zeroes=unmap"
ENV DISK_OPTS_DEV="rotation_rate=1"
ENV DISK_PATH="/xpy/diskvm"

#Network
# # (VM_NET_IP: Dont need to change coz it will ne NAT) 
# # (VM_NET_MAC: Correspond to MAC bootloader, so it will be set to GRUBCFG_MAC1 aswell)
# # (VM_NET_DHCP: It use MACVTAP which is not compatible with all configuration)
ENV VM_NET_IP="20.20.20.21"
ENV VM_NET_MAC="00:11:32:2C:A7:85"
ENV VM_NET_DHCP="N"

#Options
ENV VM_ENABLE_VGA="Y"
ENV VM_ENABLE_VIRTIO="Y"
ENV VM_ENABLE_VIRTIO_SCSI="N"
ENV VM_ENABLE_9P="N"
ENV VM_9P_PATH=""
ENV VM_9P_OPTS="local,security_model=passthrough"
ENV VM_CUSTOM_OPTS=""

ENV VM_TIMEOUT_POWERDOWN="30"

#GRUB CFG
ENV GRUBCFG_ENABLE_MOD="N"
ENV GRUBCFG_VID=""
ENV GRUBCFG_PID=""
ENV GRUBCFG_SN=""
ENV GRUBCFG_DISKIDXMAP=""
ENV GRUBCFG_SATAPORTMAP=""
ENV GRUBCFG_SASIDXMAP=""
ENV GRUBCFG_HDDHOTPLUG=""
# GRUBCFG_MAC1 will be automacticaly set to VM_NET_MAC value

VOLUME ${DISK_PATH}

ENTRYPOINT ["/usr/bin/vm-startup", "start"]

# If using ubuntu:24.10 baseline image
# Installing tools
# ARG DEBIAN_FRONTEND=noninteractive
# RUN \
#   apt-get update && \
#   apt-get install -y --no-install-recommends qemu-system-x86 qemu-utils bridge-utils dnsmasq uml-utilities iptables nftables wget net-tools procps iproute2 ethtool fdisk && \
#   apt-get install -y --no-install-recommends ethtool file netcat-openbsd unzip vim-tiny isc-dhcp-client iputils-ping kmod && \
#   apt-get autoclean && \
#   apt-get autoremove && \
#   rm -rf /var/lib/apt/lists/*

# RUN mkdir -p /qemu_cfg
COPY bin cfg /qemu_cfg/

RUN chmod -R +x /qemu_cfg/vm-* \
    && mv /qemu_cfg/vm-* /usr/bin/. \
    && echo "INF: shell scripts have been sucessfully copied to /usr/bin" \
    || ( echo "ERR: Something get wrong with shell scripts!" && exit 255 )
