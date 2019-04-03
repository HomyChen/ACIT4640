#!/bin/bash

#Disable SELinux
setenforce 0
sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config

#Update System
#yum -y install @core epel-release vim git tcpdump nmap-ncat curl nginx mariadb-server mariadb php php-mysql php-fpm
#yum -y update

#Firewall Settings
#firewall-cmd --zone=public --add-port=80/tcp --permanent
#firewall-cmd --zone=public --add-port=22/tcp --permanent
#firewall-cmd --zone=public --add-port=443/tcp --permanent

#Set ownership and permission of admin authorized keys
chmod -R u=rw,g=,o= /home/admin/.ssh
chown -R admin /home/admin/.ssh
chgrp -R admin /home/admin/.ssh
chmod u=rwx,g=,o= /home/admin/.ssh

#Turn Down Swapiness since its an SSD disk
echo "vm.swappiness = 10" >> /etc/sysctl.conf

#cp /home/admin/setup/php.ini /etc/php.ini
#cp /home/admin/setup/www.conf /etc/php-fpm.d
#cp /home/admin/setup/nginx.conf /etc/nginx/nginx.conf
#cp /home/admin/setup/info.php /usr/share/nginx/html/info.php

#cp /home/admin/setup/latest.tar.gz /home/admin/latest.tar.gz
#tar xzvf /home/admin/latest.tar.gz

chown -R nginx:wheel /usr/share/nginx/html
chown nginx:wheel /usr/share/nginx/html
chmod -R ug+w /usr/share/nginx/html

#systemctl enable mariadb
#systemctl start mariadb

mysql -u root < /home/admin/setup/mariadb_security_config.sql
systemctl restart mariadb
mysql -u root -pP@ssw0rd < /home/admin/setup/wp_mariadb_config.sql
systemctl restart mariadb

#tar xzvf /home/admin/latest.tar.gz -C /home/admin/

#cp /home/admin/setup/wp-config.php /home/admin/wordpress/wp-config.php
#rsync -avP wordpress/ /usr/share/nginx/html/
#mkdir /usr/share/nginx/html/wp-content/uploads
#chown -R admin:nginx /usr/share/nginx/html/*

#systemctl enable nginx
#systemctl start nginx
#systemctl enable mariadb
#systemctl start mariadb
#systemctl restart firewalld
#systemctl enable php-fpm
#systemctl start php-fpm