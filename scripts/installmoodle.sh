#!/bin/bash

set -ex
mountpoint=/moodle

#Setup mountpoint and fstab
grep -q -s "/srv/nfs" /etc/fstab && _RET=$? || _RET=$?
if [ $_RET = "0" ]; then
    echo "NFS is already in fstab"
else
    echo -e "\n TEST"
fi
sudo mount ${mountpoint}