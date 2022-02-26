FROM uxora/debian-kvm
LABEL maintainer="Michel VONGVILAY <https://www.uxora.com/about/me#contact-form>"
LABEL version="0.8"


ENV SCRIPT_VERSION "0.8"

# Ressources
ENV CPU "qemu64"
ENV THREADS "1"
ENV CORES "1"
ENV RAM "512"

#Bootloader
ENV BOOTLOADER_URL ""
ENV BOOTLOADER_AS_USB "Y"

#Disk
ENV DISK_SIZE "16"
ENV DISK_FORMAT "qcow2"
ENV DISK_OPTS_DRV "cache=writeback,discard=on,aio=threads,detect-zeroes=unmap"
ENV DISK_OPTS_DEV "rotation_rate=1"
ENV DISK_PATH "/xpy/diskvm"

# ENV DISK_CACHE "none" # Deprecated replace by DISK_OPTS_DRV

#Network
# # (VM_NET_IP: Dont need to change coz all is port forwarded) 
# # (VM_NET_MAC: Correspond to MAC bootloader, so it will be set to GRUBCFG_MAC1 aswell)
# # (VM_NET_DHCP: It use MACVTAP which is not compatible with all configuration)
ENV VM_NET_IP 20.20.20.21
ENV VM_NET_MAC "00:11:32:2C:A7:85"
ENV VM_NET_DHCP "N"

#Options
ENV VM_ENABLE_VGA "N"
ENV VM_ENABLE_VIRTIO "Y"
ENV VM_ENABLE_VIRTIO_SCSI "N"
ENV VM_ENABLE_9P "N"
ENV VM_9P_PATH ""
ENV VM_9P_OPTS "local,security_model=passthrough"
ENV VM_CUSTOM_OPTS ""
# VM_PATH_9P is DEPRECATED, use VM_9P_PATH instead

ENV VM_TIMEOUT_POWERDOWN "30"

#GRUB CFG
ENV GRUBCFG_AUTO "Y"
ENV GRUBCFG_VID ""
ENV GRUBCFG_PID ""
ENV GRUBCFG_SN ""
ENV GRUBCFG_DISKIDXMAP ""
ENV GRUBCFG_SATAPORTMAP ""
ENV GRUBCFG_SASIDXMAP ""
ENV GRUBCFG_HDDHOTPLUG ""
# GRUBCFG_MAC1 will be automacticaly set to VM_NET_MAC value

VOLUME ${DISK_PATH}

ENTRYPOINT /usr/bin/vm-startup

# Using uxora/devian-kvm baseline image
# Installing some more tools
ARG DEBIAN_FRONTEND=noninteractive
RUN \
  apt-get update && \
  apt-get install -y --no-install-recommends ethtool file netcat unzip vim-tiny isc-dhcp-client iputils-ping && \
  apt-get autoclean && \
  apt-get autoremove && \
  rm -rf /var/lib/apt/lists/*

# RUN mkdir -p /qemu_cfg

COPY bin cfg /qemu_cfg/

RUN chmod -R +x /qemu_cfg/vm-* \
        && mv /qemu_cfg/vm-* /usr/bin/. \
        && echo "INF: shell scripts have been sucessfully copied to /usr/bin" \
        || ( echo "ERR: Something get wrong with shell scripts!" && exit 255 )
