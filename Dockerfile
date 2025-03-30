FROM node:18-alpine

RUN mkdir -p /home/app

COPY app/package.json /home/app/
COPY app/public/ /home/app/public/
COPY app/views /home/app/views/
COPY app/index.js /home/app

WORKDIR /home/app

RUN npm install

CMD ["node","index.js"]