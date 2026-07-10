# --- Estágio de Build ---
FROM node:20-alpine AS builder

WORKDIR /app

ARG VITE_API_URL
ARG VITE_APK_BUILDER_URL
ARG VITE_DOWNLOADS_URL
ARG VITE_PANEL_URL
ENV VITE_API_URL=$VITE_API_URL \
    VITE_APK_BUILDER_URL=$VITE_APK_BUILDER_URL \
    VITE_DOWNLOADS_URL=$VITE_DOWNLOADS_URL \
    VITE_PANEL_URL=$VITE_PANEL_URL

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

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
