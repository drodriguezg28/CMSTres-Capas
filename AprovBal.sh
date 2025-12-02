#!/bin/bash

# Instalación de apache2
sudo apt update
sudo apt install apache2 -y
echo "Repositorios actualizados."

#Instalación del módulo de balanceo de carga
sudo a2enmod proxy
sudo a2enmod proxy_balancer
sudo a2enmod proxy_http

echo "Módulos de balanceo de carga habilitados."

#Configuración del balanceador de carga
sudo a2enmod ssl
cd /etc/apache2/sites-available/
cp 000-default.conf wordpress-balancer.conf
cat <<EOF > wordpress-balancer.conf
<VirtualHost *:80>
    <Proxy "balancer://webcluster">
        BalancerMember http://192.168.10.20:80
        BalancerMember http://192.168.10.21:80
        ProxySet lbmethod=byrequests
    </Proxy>

    ProxyPass "/" "balancer://webcluster/"
    ProxyPassReverse "/" "balancer://webcluster/"

    <Directory "/var/www/html">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
echo "Archivo de configuración del balanceador de carga creado."
# Habilitar nuevo sitio y deshabilitar el por defecto
sudo a2ensite wordpress-balancer.conf
sudo a2dissite 000-default.conf
sudo systemctl reload apache2
echo "Balanceador de carga configurado y activo."


sudo hostnamectl set-hostname DanielRodriguez-Bal
echo "127.0.1.1   DanielRodriguez-Bal" | sudo tee -a /etc/hosts
echo "Nombre del host cambiado a DanielRodriguez-Bal."
