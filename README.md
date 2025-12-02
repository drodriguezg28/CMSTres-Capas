Este CMS de **WordPress** montado a tráves de **AWS** está organizado en **tres capas**: pública, privada (aplicación + NFS) y privada (base de datos).

---

# INDICE 
1. [Arquitectura de la Infraestructura](#arquitectura)
2. [Seguridad](#conectividad) 
3. [Scripts de Aprovisionamiento](#aprovisionamiento)  
   - [Capa 1 – Balanceador ](#balanceador)  
   - [Capa 2 – Servidor NFS](#nfs)  
   - [Capa 2 – Servidores Web Apache](#servidores-web)  
   - [Capa 3 – Base de Datos](#bbdd)  
   - [Instalación de WordPress](#45-instalación-de-wordpress)  
   - [HTTPS con CertBot (Opcional)](#46-https-con-certbot-opcional)  
4. [Resultado Final](#5-resultado-final)



# Arquitectura
- **Capa 1 (pública)**: Balanceador de carga Apache.
- **Capa 2 (privada)**: Dos servidores web Apache + un servidor NFS con WordPress.
- **Capa 3 (privada)**: Servidor de base de datos MariaDB.

# Conectividad
- Solo la **capa 1** tiene acceso desde Internet.
- Solo hay acceso a la **capa 3** desde la **capa 1**.

## Aprovisionamiento

Cada máquina se aprovisionará mediante un script **bash**.

## Balanceador 

```bash
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
cp default-ssl.conf wordpress-balancer.conf
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

````
**Este script realiza lo siguiente:**
- Instalación de Apache.
- Habilitación de modulos necesarios para poder utilizar el balanceador
- Configuración de un sitio HTTP (Para posterior configuración HTTPS con certificado)
- Cambio del nombre del host a DanielRodriguez-Bal


## NFS
````bash
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
````
**Este script realiza lo siguiente:**
- Instalación del servidor NFS.
- Descarga de WordPress.
- Asignación de permisos a los archivos de WordPress
- Configuración de los directorios compartidos
- Cambio del nombre del host a DanielRodriguez-NFS

## Servidores Web

````bash
#!/bin/bash

# Instalación de apache y php5
sudo apt update
sudo apt install apache2 -y
sudo apt install nfs-common -y
sudo apt install php php-mysql php-cli php-xml php-gd php-mbstring php-zip php-curl libapache2-mod-php -y
echo "Apcahe2 y NFS cliente se han instalado correctamente y están activos."

# Montar el directorio NFS compartido en /var/www/html
sudo mkdir -p /var/www/html
echo "192.168.10.28:/var/www/html /var/www/html nfs defaults 0 0" | sudo tee -a /etc/fstab
sudo mount -a
sudo systemctl daemon-reload
# Asignar permisos adecuados
sudo chown -R www-data:www-data /var/www/html
sudo usermod -aG www-data www-data
sudo systemctl restart apache2
echo "Directorio NFS montado en /var/www/html."

# Configurar Apache para servir WordPress
sudo a2enmod ssl
cd /etc/apache2/sites-available/
cp  000-default.conf wordpress.conf
cat <<EOF | sudo tee /etc/apache2/sites-available/wordpress.conf
<VirtualHost *:80>
    DocumentRoot /var/www/html
    <Directory /var/www/html>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

sudo a2ensite wordpress.conf
sudo a2dissite 000-default.conf
sudo systemctl restart apache2
echo "Apache configurado para servir WordPress desde /var/www/html."

# Indicar el nuevo nombre del host
sudo hostnamectl set-hostname DanielRodriguez-Web
echo "127.0.1.1   DanielRodriguez-Web" | sudo tee -a /etc/hosts
echo "Nombre del host cambiado a DanielRodriguez-Web."
````
**Este script realiza lo siguiente:**
- Instalación de los paquetes Apache y NFS common (NFS Cliente).
- Montaje del directorio compartido a través de NFS
- Adecucación de permisos del directorio compartido
- Configuración de un sitio HTTP
- Cambio del nombre del host a DanielRodriguez-Web

## BBDD
````bash
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

c" /etc/mysql/mariadb.conf.d/50-server.cnf
sudo systemctl restart mariadb
echo "MariaDB permite conexones."

sudo hostnamectl set-hostname DanielRodriguez-BBDD
echo "127.0.1.1   DanielRodriguez-BBDD" | sudo tee -a /etc/hosts
echo "Nombre del host cambiado a DanielRodriguez-BBDD."
````
**Este script realiza lo siguiente:**
- Instalación del servidor MariaDB
- Creación de un Base de Datos y un usuario
- Asignación de permisos al usuario sobre la Base de Datos
- Cambio de
- Cambio del nombre del host a DanielRodriguez-BBDD
