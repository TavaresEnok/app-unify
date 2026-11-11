FROM nginx:alpine

# Copiar arquivos do site
COPY index.html styles.css script.js contact-form.js /usr/share/nginx/html/

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
