# CMS-en-Tres-Capas

## INDICE 
1. [Arquitectura de la Infraestructura](#2-arquitectura-de-la-infraestructura)
2. [Seguridad](#3-seguridad)  
   - [Security Groups](#31-security-groups)  
   - [ACLs de Red](#32-acls-de-red)  
4. [Scripts de Aprovisionamiento](#4-scripts-de-aprovisionamiento)  
   - [Capa 1 – Balanceador Apache](#41-capa-1--balanceador-apache)  
   - [Capa 2 – Servidores Web Apache](#42-capa-2--servidores-web-apache)  
   - [Capa 2 – Servidor NFS](#43-capa-2--servidor-nfs)  
   - [Capa 3 – Base de Datos](#44-capa-3--base-de-datos)  
   - [Instalación de WordPress](#45-instalación-de-wordpress)  
   - [HTTPS con CertBot (Opcional)](#46-https-con-certbot-opcional)  
5. [Resultado Final](#5-resultado-final)

## 2. Arquitectura de la Infraestructura

La infraestructura se divide en tres capas:

1. **Capa 1 – Pública: Balanceador de carga**
   - Apache configurado como balanceador de carga.
   - Tiene accesibilidad desde internet.
   - Desde esta capa no se tiene acceso a la capa 3.

2. **Capa 2 – Privada: Servidores Web + NFS**
   - Dos servidores web.
   - Servidor NFS con el que se comparte wordpress.

3. **Capa 3 – Privada: Base de datos**
   - Servidor BBDD.
   - Solo accesible desde la Capa 2.


## 3. Seguridad

### 3.1 Security Groups
