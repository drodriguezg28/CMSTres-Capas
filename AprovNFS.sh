#!/bin/bash

# Instalación de NFS
sudo apt update
sudo apt install nfs-kernel-server -y
echo "NFS se ha instalado correctamente y está activo."

# Preparar el entorno para WordPress
sudo mkdir -p /var/www/html

# Descargar y descomprimir WordPress
cd /var/www/html
sudo wget https://wordpress.org/latest.tar.gz
sudo tar -xzf latest.tar.gz
sudo mv wordpress/* .
sudo rm -rf wordpress
sudo rm -f latest.tar.gz
echo "WordPress se ha descargado y descomprimido en /var/www/html."

# volver al directorio principal
cd ~

# Configurar permisos para WordPress
sudo chown -R www-data:www-data /var/www/html
sudo find /var/www/html -type d -exec chmod 775 {} +
sudo find /var/www/html -type f -exec chmod 664 {} +
echo "Permisos de WordPress configurados."

#configurar NFS para compartir el directorio /var/www/html
echo "/var/www/html    192.168.10.20(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
echo "/var/www/html    192.168.10.21(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
echo "NFS se ha configurado para compartir el directorio /var/www/html."


# Indicar el nuevo nombre del host
sudo hostnamectl set-hostname DanielRodriguez-NFS
echo "127.0.1.1   DanielRodriguez-NFS" | sudo tee -a /etc/hosts
echo "Nombre del host cambiado a DanielRodriguez-NFS."
