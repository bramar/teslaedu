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
echo "NFS IP Address $nfsIpAddress" >> /tmp/log.txt

if [ ! -d $mountpoint ]; then
    sudo mkdir -p $mountpoint
fi

echo "Downloading required packages" 
sudo apt-get -y install nfs-common unzip apache2 php-mysql libapache2-mod-php7.0 mariadb-client php7.0-xml php7.0-curl php7.0-zip php7.0-gd php7.0-intl php7.0-mbstring php7.0-xmlrpc php7.0-soap
#Setup mountpoint and fstab
grep -q -s "/srv/nfs" /etc/fstab && _RET=$? || _RET=$?
if [ $_RET = "0" ]; then
    echo "NFS is already in fstab"
else
    echo -e "$nfsIpAddress:/srv/nfs\t$mountpoint\tnfs\tdefaults,rw\t0\t0" | sudo tee -a /etc/fstab
fi
sudo mount ${mountpoint}

sudo wget "https://teslaedurepo.blob.core.windows.net/mainrepo/moodle.zip?sp=r&st=2019-06-17T22:00:00Z&se=2029-12-31T23:00:00Z&spr=https&sv=2018-03-28&sig=jukPxF6eYVT3dgP8pvJTnRV%2Bke%2F5h6jvn3cYhCBmRm0%3D&sr=b" -k -O ${mountpoint}/moodle.zip
cd ${mountpoint}
unzip -qq moodle.zip
rm moodle.zip
echo "create database tedu;" > /tmp/mysql_setup.sql
echo "grant all privileges on tedu.* to 'tedu'@'%' identified by 't3duU53r2019';" >> /tmp/mysql_setup.sql
sudo mysql -u ${mysqlUsername} -p${mysqlPassword} -h ${mysqlHost} < /tmp/mysql_setup.sql
sudo chown -R www-root:www-root ${mountpoint}/* ${mountpoint}/.*