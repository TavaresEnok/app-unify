# --- Estágio de Build ---
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# --- Estágio de Produção ---
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --production

# Copiar código compilado
COPY --from=builder /app/dist ./dist

# Copiar arquivos de configuração (Firebase serviceAccountKey)
COPY --from=builder /app/src/config ./dist/config

EXPOSE 3001

CMD [ "node", "dist/index.js" ]
