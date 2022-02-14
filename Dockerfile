FROM uxora/debian-kvm
LABEL maintainer="Michel VONGVILAY <https://www.uxora.com/about/me#contact-form>"
LABEL version="0.2"

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
ENV DISK_OPT_DRV "cache=writeback,discard=on,aio=threads,detect-zeroes=on"
ENV DISK_OPT_DEV "rotation_rate=1"
ENV DISK_PATH "/image"

# ENV DISK_CACHE "none" # Deprecated replace by DISK_OPT_DRV

#Network
# # (VM_IP: Dont need to change coz all is port forwarded) 
# # (VM_MAC: Correspond to MAC bootloader, so it will be set to GRUBCFG_MAC1 aswell)
ENV VM_IP 20.20.20.21
ENV VM_MAC "00:11:32:2C:A7:85"

#Options
ENV VM_ENABLE_VGA "N"
ENV VM_ENABLE_VIRTIO "Y"
ENV VM_ENABLE_VIRTIO_SCSI "N"
ENV VM_ENABLE_9P "Y"
ENV VM_PATH_9P "/datashare"
ENV VM_CUSTOM_OPTS ""

ENV VM_TIMEOUT_POWERDOWN "10"

#GRUB CFG
ENV GRUBCFG_VID "46f4"
ENV GRUBCFG_PID "0001"
ENV GRUBCFG_SN ""
ENV GRUBCFG_DISKIDXMAP ""
ENV GRUBCFG_SATAPORTMAP ""
ENV GRUBCFG_DISKIDXMAP ""
# GRUBCFG_MAC1 will be automacticaly set to VM_MAC value

# Removed apt-get coz we use segator/qemu-kvm image
#ARG DEBIAN_FRONTEND=noninteractive
#RUN \
#  apt-get update && \
#  apt-get install -y qemu-kvm qemu-utils bridge-utils dnsmasq uml-utilities iptables wget net-tools && \
#  apt-get autoclean && \
#  apt-get autoremove && \
#  rm -rf /var/lib/apt/lists/*

RUN mkdir /qemu_cfg \
    && mkdir -p ${DISK_PATH}/cfg \
	&& mkdir -p $VM_PATH_9P

# Removed bootloader copy, using BOOTLOADER_URL download instead
# This way it can directly run from docker hub 

#COPY synoboot.im[g] /qemu_cfg/
#RUN test -f /qemu_cfg/synoboot.img \
#        || ( wget --no-check-certificate ${BOOTLOADER_URL} -O /qemu_cfg/synoboot.img 2>/dev/nul 1>&2 && echo "INF: Bootloader has been downloaded from URL." ) \
#        && find /qemu_cfg -name synoboot.img -size +49M -size -51M | grep -q . \
#        && mv /qemu_cfg/synoboot.img ${DISK_PATH%/}/bootloader.raw \
#        && echo "INF: Bootloader sucessfully copied to ${DISK_PATH%/}/bootloader.raw" \
#        || ( echo "ERR: Bootloader not found or invalid!" && exit 255 )

COPY cfg /qemu_cfg/
COPY bin /qemu_cfg/
RUN chmod -R +x /qemu_cfg/vm-* \
        && mv /qemu_cfg/vm-* /usr/bin/. \
        && echo "INF: shell scripts have been sucessfully copied to /usr/bin" \
        || ( echo "ERR: Something get wrong with shell scripts!" && exit 255 )

EXPOSE 5000
EXPOSE 5001

VOLUME $VM_PATH_9P

ENTRYPOINT /usr/bin/vm-startup
