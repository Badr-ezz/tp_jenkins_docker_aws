<<<<<<< HEAD
# Utilise une image Nginx officielle comme base
FROM nginx:latest

# Copie les fichiers de l'application dans le répertoire de Nginx
COPY app /usr/share/nginx/html

# Expose le port 80
EXPOSE 80

# Commande pour démarrer Nginx
=======
# Builder (installation des dépendances)
FROM node:18-alpine as builder
WORKDIR /home/app
COPY app/package*.json ./
RUN npm install
COPY app/ ./

# Serveur Nginx (servir directement views/)
FROM nginx:alpine
COPY --from=builder /home/app/views /usr/share/nginx/html
EXPOSE 80
>>>>>>> 95e5450a5ebf33457cd564d246b6da160c23156e
CMD ["nginx", "-g", "daemon off;"]