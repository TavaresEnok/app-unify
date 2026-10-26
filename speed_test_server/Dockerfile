FROM node:20-alpine

WORKDIR /app

COPY --chown=node:node server.js ./

USER node

# Expor porta 3001 (conforme server.js)
EXPOSE 3001

# Iniciar aplicação
CMD ["node", "server.js"]
