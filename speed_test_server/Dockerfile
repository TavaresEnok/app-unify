FROM node:20-alpine

WORKDIR /app

# Instalar dependências necessárias para speed test
RUN npm init -y && npm install express cors

# Copiar código fonte
COPY server.js ./

# Expor porta 3001 (conforme server.js)
EXPOSE 3001

# Iniciar aplicação
CMD ["node", "server.js"]
