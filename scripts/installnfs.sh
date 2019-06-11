#!/bin/bash

sudo sh -c 'echo "" > /var/log/scripts.log'
sudo sh -c 'chmod 777 /var/log/scripts.log'

log() {
    DATUM=`sudo date '+%d.%m.%Y %H:%M:%S'`
    echo "$DATUM - $1" | tee -a /var/log/scripts.log > /dev/null
}

log "STARTING NFS INSTALLATION SCRIPTS"
log "---------------------------------"
log "Partitioning NFS hdisk"
echo -e "n\np\n1\n\n\nt\n8e\np\nw\n" | sudo fdisk /dev/sdc
log "Creating LVM"
sudo pvcreate /dev/sdc1
sudo vgcreate nfs_vg /dev/sdc1
sudo lvcreate -n nfs_lv -l 100%FREE nfs_vg
log "Creating Filesystem on LVM"
sudo mkfs.ext4 /dev/nfs_vg/nfs_lv
log "Installing NFS Server"
sudo apt-get install nfs-kernel-server nfs-common -y | tee -a /var/log/scripts.log > /dev/null
log "Creating mountpoint for nfs"
sudo mkdir -p /srv/nfs
log "Optimizing permissions"
sudo chown nobody:nogroup /srv/nfs
log "Adding automount to fstab"
sudo sh -c 'echo "/dev/nfs_vg/nfs_lv\t/srv/nfs\tauto\tdefaults\t0\t0" >> /etc/fstab'
log "Mounting nfs storage"
sudo sh -c 'mount /srv/nfs'
df -h | tee -a /var/log/scripts.log > /dev/null
log "Exporting mountpoing"
echo -e "/srv/nfs\t10.0.0.0/24(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports > /dev/null
log "Exported mountpoints"
sudo showmount -e localhost | sudo tee -a /var/log/scripts.log > /dev/null
exit 0