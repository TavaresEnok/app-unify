FROM node:20-alpine

WORKDIR /app

COPY --chown=node:node package*.json ./
RUN npm ci --omit=dev --loglevel=error

COPY --chown=node:node . .

USER node

EXPOSE 3002

CMD ["node", "index.js"]
