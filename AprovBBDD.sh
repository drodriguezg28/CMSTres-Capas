#!/bin/bash

# Instalación de mariadb-server
sudo apt update
sudo apt install mariadb-server -y
echo "MariaDB se ha instalado correctamente y está activo."

mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE wordpress;
CREATE USER 'wordpressuser'@'%' IDENTIFIED BY 'WordPress123456789';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpressuser'@'%';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

sudo hostnamectl set-hostname DanielRodriguez-BBDD
echo "Nombre del host cambiado a DanielRodriguez-BBDD."
