FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm i --only=production
COPY server.js .
EXPOSE 80
CMD ["node", "server.js"]