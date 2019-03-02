#!/bin/bash
mysql -u root < /home/admin/setup/mariadb_security_config.sql
mysql -u root -pP@ssw0rd < /home/admin/setup/wp_mariadb_config.sql
systemctl restart mariadb

tar xzvf /home/admin/latest.tar.gz -C /home/admin/

cp /home/admin/setup/wp-config.php /home/admin/wordpress/wp-config.php
rsync -avP wordpress/ /usr/share/nginx/html/
mkdir /usr/share/nginx/html/wp-content/uploads
chown -R admin:nginx /usr/share/nginx/html/*

systemctl disable wp_mariadb_config.service
rm -rf /usr/lib/systemd/system/wp_mariadb_config.service
rm -rf /etc/systemd/system/multi-user.target.wants/wp_mariadb_config.service