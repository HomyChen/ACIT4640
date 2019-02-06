#!/bin/bash

#--------MANUAL SETUP START--------------------

##------------Set up networking

#echo "192.168.254.10    wp.snp.acit" >> /etc/hosts
#sed -i -e 's/BOOTPROTO=dhcp/BOOTPROTO=static/g' /etc/sysconfig/network-scripts/ifcfg-enp0s3
#sed -i -e 's/ONBOOT=no/ONBOOT=yes/g' /etc/sysconfig/network-scripts/ifcfg-enp0s3
#echo "IPADDR=192.168.254.10" >> /etc/sysconfig/network-scripts/ifcfg-enp0s3
#echo "NETWORKING=yes" >> /etc/sysconfig/network
#echo "HOSTNAME=centos7" >> /etc/sysconfig/network
#echo "GATEWAY=192.168.254.1" >> /etc/sysconfig/network
#echo "nameserver 8.8.8.8" >> /etc/resolv.conf
#echo "nameserver 8.8.4.4" >> /etc/resolv.conf

##------------Add user---------------

#useradd admin
#echo "P@ssw0rd" | passwd admin --stdin
#usermod -aG wheel admin

##------------Give admin sudo without password-------------

#sudo sh -c 'echo "admin ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers'

##------------Make authorized keys---------------------------

#su admin
#mkdir ~/.ssh/
#chmod 700 ~/.ssh/
#touch ~/.ssh/authorized_keys
#chmod 600 ~/.ssh/authorized_keys

##------------------SSH from host machine
#ssh -p 50022 admin@127.0.0.1
##SCP to copy pub key file
#scp -P 50022 acit_admin_id_rsa.pub admin@127.0.0.1:/home/admin/.ssh

##------------------Copy pub file into authorized keys
#cat ~/.ssh/acit_admin_id_rsa.pub >> ~/.ssh/authorized_keys

##-----------------MANUAL SETUP END----------------------------------

#------------------disable SELinux
ssh wp "
echo 'Disabling SELinux...';
sudo setenforce 0; 
sudo sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config;
exit
"

#------------------install packages
ssh wp "
echo 'Installing packages...';
sudo yum -y install @core epel-release vim git tcpdump nmap-ncat curl;
sudo yum -y update;
exit
"

#------------------firewall setting
ssh wp "
echo 'Tweaking firewall settings...';
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent;
sudo firewall-cmd --zone=public --add-port=22/tcp --permanent;
sudo firewall-cmd --zone=public --add-port=443/tcp --permanent;
sudo systemctl restart firewalld;
exit
"

#------------------nginx
ssh wp "
echo 'Nginx setup....';
sudo yum -y install nginx;
sudo systemctl start nginx;
sudo systemctl enable nginx;
sudo systemctl status nginx;
sudo systemctl enable nginx;
exit
"

#------------------mariadb
ssh wp "
echo 'MariaDB setup...';
sudo yum install -y mariadb-server mariadb;
sudo systemctl start mariadb;

touch mariadb_security_config.sql;
echo \"UPDATE mysql.user SET Password=PASSWORD('P@ssw0rd') WHERE User='root';\" >> mariadb_security_config.sql;
echo \"DELETE FROM mysql.user WHERE User='';\" >> mariadb_security_config.sql;
echo \"DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');\" >> mariadb_security_config.sql;
echo \"DROP DATABASE test;\" >> mariadb_security_config.sql;
echo \"DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';\" >> mariadb_security_config.sql;
echo \"P@ssw0rd\" | mysql -u root -p < mariadb_security_config.sql;
sudo systemctl enable mariadb;
exit
"

#------------------PHP
ssh wp "
echo 'PHP Setup...';
sudo yum install -y php php-mysql php-fpm;
sudo sed -i -e 's/;cgi.fix_pathinfo=1/chi.fix_pathinfo=0/g' /etc/php.ini;
sudo sed -i -e 's#listen = 127.0.0.1:9000#listen = /var/run/php-fpm/php-fpm.sock#g' /etc/php-fpm.d/www.conf;
sudo sed -i -e 's#;listen.owner = nobody#listen.owner = nobody#g' /etc/php-fpm.d/www.conf;
sudo sed -i -e 's#;listen.group = nobody#listen.group = nobody#g' /etc/php-fpm.d/www.conf;
sudo sed -i -e 's#user = apache#user = nginx#g' /etc/php-fpm.d/www.conf;
sudo sed -i -e 's#group = apache#group = nginx#g' /etc/php-fpm.d/www.conf;

sudo systemctl start php-fpm;
sudo systemctl enable php-fpm;

exit
"
scp nginx_new.conf wp:/home/admin/

ssh wp "
sudo cp nginx_new.conf /etc/nginx/nginx.conf;

sudo touch /usr/share/nginx/html/info.php;
sudo sh -c 'echo \"<?php phpinfo(); ?>\" >> /usr/share/nginx/html/info.php';
sudo systemctl restart nginx;
exit
"

#------------------Wordpress Database Configuration
ssh wp "
echo 'Configuring Wordpress DB...';
touch wp_mariadb_config.sql;
echo \"CREATE DATABASE wordpress;\" >> wp_mariadb_config.sql;
echo \"CREATE USER wordpress_user@localhost IDENTIFIED BY 'P@ssw0rd';\" >> wp_mariadb_config.sql;
echo \"GRANT ALL PRIVILEGES ON wordpress.* TO wordpress_user@localhost;\" >> wp_mariadb_config.sql;
echo \"FLUSH PRIVILEGES;\" >> wp_mariadb_config.sql;

echo \"P@ssw0rd\" | mysql -u root -p < wp_mariadb_config.sql;
exit
"

#------------------Wordpress Source Setup
ssh wp "
echo 'Wordpress Source Setup....';
sudo yum install -y wget;
wget https://wordpress.org/latest.tar.gz;
tar xzvf latest.tar.gz;
cp wordpress/wp-config-sample.php wordpress/wp-config.php;

sed -i -e 's/database_name_here/wordpress/g' ./wordpress/wp-config.php;
sed -i -e 's/username_here/wordpress_user/g' ./wordpress/wp-config.php;
sed -i -e 's/password_here/P@ssw0rd/g' ./wordpress/wp-config.php;

sudo rsync -avP wordpress/ /usr/share/nginx/html/;
sudo mkdir /usr/share/nginx/html/wp-content/uploads;
sudo chown -R admin:nginx /usr/share/nginx/html/*;
exit
"

#------------------Install Virtualbox Guest Additions
#------------------Installing pre-requisities
ssh wp "
echo 'Installing Virtualbox Guest Additions pre-requisities...';
sudo yum -y install kernel-devel kernel-headers dkms gcc gcc-c++ kexec-tools;
exit
"

#------------------Creating mount point, mounting, and installing VirtualBox Guest Additions
#------------------Assumes that the virtualbox guest additions CD is in /dev/cdrom
ssh wp "
echo 'Installing VirtualBox Guest Additions...';
mkdir vbox_cd;
sudo mount /dev/cdrom ./vbox_cd;
./vbox_cd/VBoxLinuxAdditions.run;
sudo umount ./vbox_cd;
rmdir ./vbox_cd;
exit"
