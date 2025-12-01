#!/bin/bash

# Instalación de apache y php5
sudo apt update
apt install apache2 -y
sudo apt install php php-mysql php-cli php-xml php-gd php-mbstring php-zip php-curl libapache2-mod-php -y
echo "Apcahe2 y NFS cliente se han instalado correctamente y están activos."

# Montar el directorio NFS compartido en /var/www/html
sudo mkdir -p /var/www/html
echo "192.168.10.20:/var/www/wordpress /var/www/html nfs defaults 0 0" | sudo tee -a /etc/fstab
sudo mount -a
sudo systemctl daemon-reload
# Asignar permisos adecuados
sudo chown -R www-data:www-data /var/www/html
sudo usermod -aG www-data www-data
sudo systemctl restart apache2
echo "Directorio NFS montado en /var/www/html."

# Configurar Apache para servir WordPress
cd /etc/apache2/sites-available/
cp 000-default.conf wordpress.conf
cat <<EOF >> wordpress.conf
    <Directory /var/www/wordpress>
        AllowOverride All
        Require all granted
    </Directory>
EOF
sudo a2ensite wordpress.conf
sudo a2dissite 000-default.conf
sudo systemctl restart apache2
echo "Apache configurado para servir WordPress desde /var/www/html."

sudo hostnamectl set-hostname DanielRodriguez-Web
echo "Nombre del host cambiado a DanielRodriguez-Web."