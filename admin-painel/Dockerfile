# --- Estágio de Build ---
FROM node:20-alpine AS builder

WORKDIR /app

# Copiar arquivos de dependência
COPY package*.json ./

# Instalar dependências
RUN npm ci

# Copiar código fonte
COPY . .

# Build de produção
RUN npm run build

# --- Estágio de Produção com Nginx ---
FROM nginx:alpine

# Copiar arquivos buildados
COPY --from=builder /app/dist_final /usr/share/nginx/html

# Configuração Nginx para SPA (Single Page Application)
RUN echo 'server { \
    listen 80; \
    gzip on; \
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript; \
    gzip_min_length 1000; \
    location / { \
    root /usr/share/nginx/html; \
    index index.html; \
    try_files $uri $uri/ /index.html; \
    add_header Cache-Control "no-store, no-cache, must-revalidate"; \
    } \
    }' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
