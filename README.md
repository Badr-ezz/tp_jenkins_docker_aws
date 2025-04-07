# Rapport de Mini-Projet Aws Jenkins

## Réalisé par :
- Anas Slimani
- Badr Ezziyati

---

## Sommaire
1. [Introduction](#introduction)
2. [Présentation du DockerFile](#présentation-du-dockerfile)
3. [Test et validation du conteneur API](#test-et-validation-du-conteneur-api)
4. [Déploiement avec Docker Compose](#déploiement-avec-docker-compose)
5. [Mise en place du registre privé Docker](#mise-en-place-du-registre-privé-docker)

---

## Introduction

Dans le cadre des pratiques modernes de développement logiciel, l'automatisation des processus d'intégration et de déploiement est devenue essentielle pour garantir rapidité, fiabilité et qualité des applications. Ce rapport présente la mise en œuvre d'un pipeline CI/CD (Intégration Continue/Déploiement Continu) pour le déploiement automatisé d'une application web statique, en utilisant Jenkins comme outil d'orchestration et AWS comme plateforme d'hébergement.

L'objectif principal de ce projet est de concevoir un pipeline robuste qui assure la construction, les tests, la publication et le déploiement de l'application dans différents environnements simulés (review, staging, production). Pour y parvenir, nous avons utilisé des technologies telles que Docker pour la conteneurisation, Nginx comme serveur web, et Docker Hub pour le stockage des images. Jenkins, avec son système de pipelines déclaratifs, permet d'automatiser l'ensemble de ces étapes, réduisant ainsi les erreurs humaines et accélérant le cycle de livraison.

Ce document détaille les étapes clés du projet, depuis la configuration du Dockerfile et du Jenkinsfile jusqu'aux déploiements successifs sur AWS. Les captures d'écran et les références Git incluses illustrent la mise en pratique des concepts théoriques, offrant une vision complète et concrète de l'implémentation d'une chaîne CI/CD efficace.

À travers ce rapport, nous mettons en lumière les bonnes pratiques et les défis rencontrés, tout en démontrant comment l'automatisation peut transformer le processus de déploiement d'une application web.

---

## Présentation du DockerFile

Voici le Dockerfile utilisé pour créer l'image du static app  :

### 1. code de Dockerfile:

```dockerfile
FROM node:18-alpine as builder
WORKDIR /home/app
COPY app/package*.json ./
RUN npm install
COPY app/ ./

FROM nginx:alpine
COPY --from=builder /home/app/views /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"] 
```

* Ce Dockerfile utilise une architecture multi-étapes pour optimiser la construction et le déploiement d'une application web statique. Dans la première étape, basée sur Node.js 18 Alpine, les dépendances de l'application sont installées et le code source est copié. La seconde étape utilise une image légère Nginx Alpine pour servir uniquement les fichiers statiques (contenus dans le dossier `views`), éliminant ainsi les outils de build inutiles en production. Cette approche réduit considérablement la taille de l'image finale, améliore la sécurité en limitant les composants installés, et garantit des performances optimales grâce à Nginx pour la diffusion des contenus statiques. Le port 80 est exposé pour permettre l'accès à l'application, tandis que la commande CMD maintient Nginx en fonctionnement continu.



## Préparation de la machine aws Ubuntu

![image1](C:/Users/Osaka Gaming Maroc/Desktop/tp_jenkins_docker_aws/screens/image1.jpg)

---

###  Démarage de container: 
![démarage de container ](./screens/runningcontainer.png)
---

###  Récupération des données d’apres le fichier student_age.json: 
![démarage de container ](./screens/testing%20the%20api.png)
---

## Déploiement-avec-docker-compose

### Explication du fichier docker compose : 

####  1. Définition de la version de Docker Compose :

```yaml
version: '3'
```
* Spécifie que le fichier utilise la version 3 de
 Docker Compose, une version stable et
 largement utilisée.

####  2. Définition des services : 
```yaml
services:
```

Ce fichier définit deux services :
- **supmit_api** → L’API Flask qui fournit la liste des étudiants.
- **website** → L’application web en PHP qui consomme l’API.


#### 3. Service : supmit_api (API Flask)
```yaml
  supmit_api :
    image: supmit:latest  
    ports:
      - "5000:5000"  
    volumes:
      - ./simple_api/student_age.json:/data/student_age.json  
    networks:
      - student-net  
```

- **image**: supmit:latest(au lieu de supmit:1.0) → Utilise l’image
 Docker "supmit", construite précédemment, avec le tag latest.
- **ports**:
    - **5000:5000** → Mappe le port 5000 du conteneur sur le port
 5000 de la machine hôte.
- **volumes**:
    - **./simple_api/student_age.json:/data/student_age.json** 
        - **Monte le fichier student_age.json de l’hôte dans le
 dossier /data du conteneur pour que l’API puisse
 accéder aux données.**
 - **networks**:
 student-net → Ajoute le conteneur au réseau student-net,
 permettant la communication avec le frontend.

#### 4. Service : website (Application PHP + Apache)

```yaml
  website:
    image: php:apache  
    ports:
      - "80:80"  
    environment:
      - USERNAME=root  
      - PASSWORD=root  
    volumes:
      - ./website:/var/www/html  
    depends_on:
      - supmit_api  
    networks:
      - student-net
```


- **`image: php:apache`** : Utilise l’image officielle PHP avec Apache pour servir le site web.
- **`ports:`**
  - `80:80` : Mappe le port 80 du conteneur sur le port 80 de la machine hôte, rendant le site accessible via `http://localhost`.
- **`environment:`**
  - Définit les variables d’environnement `USERNAME` et `PASSWORD` (probablement utilisées pour l’authentification avec l’API).
- **`volumes:`**
  - `./website:/var/www/html` : Monte le dossier `./website` de l’hôte dans `/var/www/html` du conteneur pour que le site web puisse être servi.
- **`depends_on:`**
  - `submit_api` : Assure que l’API démarre avant le site web, évitant les erreurs de connexion au backend.
- **`networks:`**
  - `student-net` : Relie ce service au même réseau que l’API, permettant leur communication.

#### 5. Définition du réseau : 
```yaml
networks:
  student-net:
```  
-  Définit un réseau Docker personnalisé (student-net)
 pour que les conteneurs puissent communiquer entre
 eux.

### 6. Exécution de la commande docker-compose up -d

![démarage de docker-compose](./screens/runningdockercompose.png)
---

![lister les étudiants via http://localhost:80](./screens/list_students.png)



## Mise en place du registre privé Docker

### explication du fichier docker-compose-registry : 
#### - Services
Les services définissent les conteneurs qui seront lancés par Docker Compose. Dans ce fichier, deux services sont définis : registry et registry-ui.

#### Service registry : 
```yaml
registry:
  image: registry:2  
  container_name: registry
  ports:
    - "5000:5000"  
  volumes:
    - registry_data:/var/lib/registry 
  networks:
    - registry-net
```

- **image: registry:2** : Utilise l'image officielle de Docker Registry (version 2) pour créer le conteneur. Cette image permet de déployer un registre privé pour stocker des images Docker.

- **container_name**: registry : Donne un nom explicite au conteneur (registry) pour faciliter son identification.

- **ports: - "5000:5000"** : Mappe le port 5000 du conteneur sur le port 5000 de la machine hôte. Cela permet d'accéder au registre via http://localhost:5000.

- **volumes: - registry_data:/var/lib/registry** : Crée un volume Docker nommé registry_data et le monte dans le conteneur à l'emplacement /var/lib/registry. Ce volume est utilisé pour stocker les images Docker de manière persistante (les données ne sont pas perdues lorsque le conteneur est redémarré ou supprimé).

- **networks: - registry-net** : Connecte ce service au réseau Docker personnalisé registry-net. Cela permet au registre de communiquer avec d'autres services sur le même réseau.

### Service registry-ui
```yaml
registry-ui:
  image: joxit/docker-registry-ui:latest 
  container_name: registry-ui
  ports:
    - "8080:80" 
  environment:
    - REGISTRY_TITLE=SUPMIT Private Registry  
    - REGISTRY_URL=http://localhost:5000 
  depends_on:
    - registry  
  networks:
    - registry-net
```
- **image: joxit/docker-registry-ui:latest** : Utilise l'image joxit/docker-registry-ui pour fournir une interface web conviviale pour gérer le registre Docker.

- **container_name: registry-ui** : Donne un nom explicite au conteneur (registry-ui) pour faciliter son identification.

- **ports: - "8080:80"** : Mappe le port 80 du conteneur sur le port 8080 de la machine hôte. Cela permet d'accéder à l'interface web via http://localhost:8080.

- **environment :** Définit des variables d'environnement pour configurer l'interface web :

    - **REGISTRY_TITLE=SUPMIT Private Registry** : Définit le titre de l'interface web.

  - **REGISTRY_URL=http://localhost:5000**: Spécifie l'URL du registre Docker auquel l'interface web doit se connecter. Ici, elle pointe vers http://localhost:5000.

- **depends_on: - registry** : Indique que le service registry-ui dépend du service registry. Cela garantit que le registre Docker démarre avant l'interface web.

- **networks: - registry-net** : Connecte ce service au même réseau Docker personnalisé (registry-net) que le registre, permettant une communication entre les deux services.

### 3. Volumes
```yml
volumes:
  registry_data:
```

- **Explication** : Définit un volume Docker nommé registry_data. Ce volume est utilisé pour stocker les données du registre Docker de manière persistante. Il est monté dans le conteneur registry à l'emplacement /var/lib/registry.

### 4. Réseaux
```yml
networks:
  registry-net:
```

- **Explication :** Définit un réseau Docker personnalisé nommé registry-net. Ce réseau permet aux services registry et registry-ui de communiquer entre eux. Les conteneurs sur le même réseau peuvent se "voir" et interagir.

## Test : 
* Démarage de docker-compose-registry : 

 ![démarer docker-compose-registry](./screens/lanch%20docker-compose-registry.png)

* push supmit image to localhost:5000

 ![push supmit image to localhost:5000](./screens/push%20supmit%20image%20on%20the%20registry.png)

 * push test : 

 ![push test](./screens/check%20supmit%20push.png)