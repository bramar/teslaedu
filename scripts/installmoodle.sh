#!/bin/bash

. ./helperfunctions.sh

set -ex
mountpoint=/moodle

get_setup_params || exit 99

echo "Moodle setup started" > /tmp/log.txt
echo "Get setup parameters" >> /tmp/log.txt
echo "Site FQDN $siteFQDN" >> /tmp/log.txt
echo "MySQL Username $mysqlUsername" >> /tmp/log.txt
echo "MySQL Password $mysqlPassword" >> /tmp/log.txt
echo "MySQL FQDN     $mysqlHost" >> /tmp/log.txt

#Setup mountpoint and fstab
grep -q -s "/srv/nfs" /etc/fstab && _RET=$? || _RET=$?
if [ $_RET = "0" ]; then
    echo "NFS is already in fstab"
else
    echo -e "\n TEST"
fi
sudo mount ${mountpoint}
