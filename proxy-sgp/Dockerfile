FROM node:20-alpine

WORKDIR /app

# Copiar package files
COPY package*.json ./

# Instalar dependências
RUN npm ci --only=production

# Copiar código fonte
COPY index.js ./
COPY *.php ./

# Criar diretório para o banco SQLite
RUN mkdir -p /data

# Expor porta
EXPOSE 3001

# Variáveis de ambiente
ENV NODE_ENV=production
ENV PORT=3001

# Comando de inicialização
CMD ["node", "index.js"]
