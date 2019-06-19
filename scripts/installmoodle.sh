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

export siteroot=/var/www/html

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

# Get moodle
cd /var/www/html
sudo rm index.html
sudo wget "https://teslaedurepo.blob.core.windows.net/mainrepo/moodle.zip?sp=r&st=2019-06-17T22:00:00Z&se=2029-12-31T23:00:00Z&spr=https&sv=2018-03-28&sig=jukPxF6eYVT3dgP8pvJTnRV%2Bke%2F5h6jvn3cYhCBmRm0%3D&sr=b" -k -O /var/www/html/moodle.zip
sudo unzip -q moodle.zip
sudo rm moodle.zip
sudo chown -R www-data:www-data .

echo "create database tedu;" > /tmp/mysql_setup.sql
echo "grant all privileges on tedu.* to 'tedu'@'%' identified by 't3duU53r2019';" >> /tmp/mysql_setup.sql
sudo mysql -u ${mysqlUsername} -p${mysqlPassword} -h ${mysqlHost} < /tmp/mysql_setup.sql

sudo -u www-data php ${siteroot}/admin/cli/install.php --chmod=777  --lang=en --wwwroot="${siteFQDN}" --dataroot="${mountpoint}" --dbhost="${mysqlHost}" --dbname='tedu' --dbuser="tedu@${mysqlHost}" --dbpass='t3duU53r2019' --fullname='TESLA EDU' --shortname='tedu' --adminuser="${teslaEduAdminUsername}" --adminpass="${teslaEduAdminPassword}" --adminemail="${teslaEduAdminEmail}" --non-interactive --agree-license --allow-unstable || true

sudo cat > /tmp/moodleConfig.sql << EOF
UPDATE mdl_config SET value ='manual'  WHERE name ='auth';
UPDATE mdl_config SET value ='manual,guest,self,cohort,ldap,meta'  WHERE name ='enrol_plugins_enabled';
UPDATE mdl_config SET value ='tedu'  WHERE name ='theme';
UPDATE mdl_config SET value ='1'  WHERE name ='enablewebservices';
UPDATE mdl_config SET value ='0'  WHERE name ='autologinguests';
UPDATE mdl_config SET value ='1'  WHERE name ='autolang';
UPDATE mdl_config SET value ='en'  WHERE name ='lang';
UPDATE mdl_config SET value ='1'  WHERE name ='langmenu';
UPDATE mdl_config SET value ='1'  WHERE name ='defaulthomepage';
UPDATE mdl_config SET value ='1'  WHERE name ='navshowcategories';
INSERT INTO mdl_config SET value ='1', name ='navexpandmycourses';
UPDATE mdl_config SET value ='1'  WHERE name ='enablemobilewebservice';
UPDATE mdl_config SET value ='Europe/Belgrade'  WHERE name ='timezone';
INSERT INTO mdl_config SET value ='rest,xmlrpc', name ='webserviceprotocols';
UPDATE mdl_config SET value ='2'  WHERE name ='grade_report_overview_showtotalsifcontainhidden';
UPDATE mdl_config SET value ='0,10,11,12,2,4,6,8,13'  WHERE name ='grade_aggregations_visible';
UPDATE mdl_config SET value ='1'  WHERE name ='grade_aggregateonlygraded';
UPDATE mdl_config SET value ='ods,txt,xls,xml'  WHERE name ='gradeexport';
UPDATE mdl_config SET value ='1'  WHERE name ='enablemobilewebservice';
UPDATE mdl_config SET value ='1'  WHERE name ='authloginviaemail';
EOF
sudo mysql -u ${mysqlUsername} -p${mysqlPassword} -h ${mysqlHost} tedu < /tmp/moodleConfig.sql

sudo systemctl reload apache2
