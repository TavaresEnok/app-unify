FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev --loglevel=error

COPY . .

EXPOSE 3002

CMD ["node", "index.js"]
