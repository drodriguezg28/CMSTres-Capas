Este CMS de **WordPress** montado a través de **AWS** está organizado en **tres capas**: pública, privada (aplicación + NFS) y privada (base de datos).

---

# ÍNDICE 
1. [Arquitectura de la Infraestructura](#arquitectura)
2. [Conectividad](#conectividad) 
3. [Scripts de Aprovisionamiento](#aprovisionamiento)  
   - [Balanceador](#balanceador)  
   - [Servidor NFS](#nfs)  
   - [Servidores Web](#servidores-web)  
   - [Base de Datos](#bd)  
   - [Certificación de HTTPS con CertBot](#certbot)  
4. [Sitio Web](#sitio-web)



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
```sh
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

```
***Este script realiza lo siguiente:***
- Instalación de Apache.
- Habilitación de módulos necesarios para poder utilizar el balanceador
- Configuración de un sitio HTTP (Para posterior configuración HTTPS con certificado)
- Cambio del nombre del host a DanielRodriguez-Bal


## NFS
```bash
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
```
***Este script realiza lo siguiente:***
- Instalación del servidor NFS.
- Descarga de WordPress.
- Asignación de permisos a los archivos de WordPress
- Configuración de los directorios compartidos
- Cambio del nombre del host a DanielRodriguez-NFS

## Servidores Web
```bash
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
```
***Este script realiza lo siguiente:***
- Instalación de los paquetes Apache y NFS Common (NFS Cliente).
- Montaje del directorio compartido a través de NFS
- Adecuación de permisos del directorio compartido
- Configuración de un sitio HTTP
- Cambio del nombre del host a DanielRodriguez-Web

## BD
```bash
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

sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf
sudo systemctl restart mariadb
echo "MariaDB permite conexones."

sudo hostnamectl set-hostname DanielRodriguez-BBDD
echo "127.0.1.1   DanielRodriguez-BBDD" | sudo tee -a /etc/hosts
echo "Nombre del host cambiado a DanielRodriguez-BBDD."
```
***Este script realiza lo siguiente:***
- Instalación del servidor MariaDB
- Creación de un Base de Datos y un usuario
- Asignación de permisos al usuario sobre la Base de Datos
- Permisos a conexiones remotas
- Cambio del nombre del host a DanielRodriguez-BBDD

## Certbot
Se genera el certificado para el dominio **elitescout.ddns.net**
```bash
sudo certbot --apache -d elitescout.ddns.net --non-interactive --agree-tos --redirect --hsts --uir
```
***Se le dan las siguientes :***
- **apache:** Modifica los virtual hosts de Apache para HTTPS.
- **d:** Apunta solo a ese dominio.
- **non-interactive:** Se ejecuta sin pedir confirmación.
- **agree-tos:** Acepta automáticamente los términos y condicioens de Let's Encrypt.
- **redirect:** Redirige todas las peticiones a *HTTP* hacia *HTTPS*
- **hsts:** Obliga a los navegadores a utilizar HTTPS.
- **uir:** Obliga al navegador a actualizar cualquier recurso que pudiera abrirse en *HTTP* a *HTTPS*


# Configuraciones en AWS
## Instancias
**Se crearon las siguientes Instancias:**
- Balanceador
- WebServer1
- WebServer2
- NFS
- BBDD

## Red
### VPC
***Se creó:***
- Una VPC llamada **WordPress-vpc** en la red ```192.168.10.0/24```
     - Dos Subredes **Privadas**:
       1. Bal-Web-NFS: Realiza la conexión entre el Balanceador y los Servidores Web, y de estos últimos con el NFS.
          - Subred: ````192.168.10.16/28```` ➡️ ```192.168.10.17``` hasta ```192.168.10.30```
       2. Web-BD: Realiza la conexión entre los Servidores Web y la Base de Datos
          - Subred: ````192.168.10.32/28```` ➡️ ```192.168.10.33``` hasta ```192.168.10.46```
     - Una Subred **Pública**
       1. Pública: Da salida a Internet a través del Balanceador
          - Subred: ````192.168.10.0/28```` ➡️ ```192.168.10.1``` hasta ```192.168.10.17```
### IP's de cada instancia
- Balanceador
     1. Interfaz de subred Pública: ```192.168.10.10```
     2. Interfaz de subred Bal-Web-NFS: ```192.168.10.25```
- WebServer1
     1. Interfaz de subred Bal-Web-NFS: ```192.168.10.20```
     2. Interfaz de subred Web-BD: ```192.168.10.41```
- WebServer2
     1. Interfaz de subred Bal-Web-NFS: ```192.168.10.21```
     2. Interfaz de subred Web-BD: ```192.168.10.42```
- NFS
     1. Interfaz de subred Bal-Web-NFS: ```192.168.10.28```
- BBDD
     1. Interfaz de subred Web-BD: ```192.168.10.45```



## Seguridad

### Listas de Control de Acceso (ACL)
Se Configuró una ACL asignada a la capa 3 (BD) para que solo pudiera recibir conexion directa de la capa 2.

### Grupos de Seguridad (GS)
Se han creado cuatro grupos de seguridad, uno para cada tipo de instancia, cada una de ellas permite **(Protocolo:Puerto)**:
- GS-Balanceador
  1. ```HTTP:80``` (Para poder actualizar los certificados)
  2. ```HTTPS:443``` (Para las peticiones web)
  3. ```SSH:22``` (Para la conexión remota)
- GS-WebServer
  1. ```HTTP:80``` (Para recibir las peticiones web desde el balanceador | Permitido solo desde GS-Balanceador)
  2. ```SSH:22``` (Para la conexión remota)
- GS-NFS
  1. ```NFS:2049``` (Para poder servir NFS a los servidores web | Permitido solo desde GS-WebServer)
  2. ```SSH:22``` (Para la conexión remota)
- GS-BBDD
  1. ```MYSQL:3306``` (Para poder suministrar datos a los servidores web | Permitido solo desde GS-WebServer)
  2. ```SSH:22``` (Para la conexión remota)

# Sitio Web
El dominio elegido para el sitio web es [elitescout.ddns.net](https://elitescout.ddns.net/)
