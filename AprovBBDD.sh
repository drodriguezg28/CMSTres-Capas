#!/bin/bash

# Instalación de mariadb-server
sudo apt update
sudo apt install mariadb-server -y
echo "MariaDB se ha instalado correctamente y estÃ¡ activo."

mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE wordpress;
CREATE USER 'wordpressuser'@'%' IDENTIFIED BY 'WordPress123456789';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpressuser'@'%';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf
sudo systemctl restart mariadb
echo "MariaDB permite conexones."


sudo hostnamectl set-hostname DanielRodriguez-BBDD
echo "127.0.1.1   DanielRodriguez-BBDD" | sudo tee -a /etc/hosts
echo "Nombre del host cambiado a DanielRodriguez-BBDD."

