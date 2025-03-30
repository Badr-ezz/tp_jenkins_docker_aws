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
CMD ["nginx", "-g", "daemon off;"]