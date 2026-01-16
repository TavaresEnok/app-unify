FROM node:20-alpine

WORKDIR /app

# Instalar dependências necessárias para speed test
RUN npm init -y && npm install express cors

# Copiar código fonte
COPY server.js ./

# Expor porta
EXPOSE 3002

# Iniciar aplicação
CMD ["node", "server.js"]
