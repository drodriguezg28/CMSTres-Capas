#!/bin/bash

# Instalación de NFS
sudo apt update
sudo apt install apache2 -y
sudo apt install nfs-kernel-server -y
echo "NFS se ha instalado correctamente y está activo."

# Preparar el entorno para WordPress
sudo a2enmod rewrite
sudo mkdir -p /var/www/wordpress

# Descargar y descomprimir WordPress
cd /var/www/wordpress
sudo wget https://wordpress.org/latest.tar.gz
sudo tar -xzf latest.tar.gz
sudo mv wordpress/* .
sudo rm -rf wordpress
sudo rm -f latest.tar.gz
echo "WordPress se ha descargado y descomprimido en /var/www/wordpress."

# volver al directorio principal
cd ~

# Configurar permisos para WordPress
sudo chown -R www-data:www-data /var/www/wordpress
sudo find /var/www/wordpress -type d -exec chmod 775 {} \;
sudo find /var/www/wordpress -type f -exec chmod 664 {} \;
echo "Permisos de WordPress configurados."

#configurar NFS para compartir el directorio /var/www/html
echo "/var/www/wordpress    192.168.10.21(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
echo "/var/www/wordpress    192.168.10.22(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
echo "NFS se ha configurado para compartir el directorio /var/www/wordpress."

# Configurar Apache para servir WordPress
sudo a2enmod ssl 
cd /etc/apache2/sites-available/
cp 000-default.conf wordpress.conf
sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/wordpress|' wordpress.conf
sudo sed -i '/<\/VirtualHost>/i \
<Directory /var/www/wordpress>\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>' wordpress.conf

sudo a2ensite wordpress.conf
sudo a2dissite 000-default.conf
sudo systemctl restart apache2
echo "Apache configurado para servir WordPress desde /var/www/wordpress."

sudo hostnamectl set-hostname DanielRodriguez-NFS
echo "Nombre del host cambiado a DanielRodriguez-NFS."