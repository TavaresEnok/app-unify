FROM nginx:alpine

# Copiar arquivos do site
COPY index.html styles.css script.js /usr/share/nginx/html/
COPY img /usr/share/nginx/html/img

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
