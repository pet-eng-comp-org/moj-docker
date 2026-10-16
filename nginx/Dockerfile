# Imagem "web" do MOJ do PET: o nginx com o vhost e os arquivos estáticos do cdmoj.
# Contexto de build = a raiz do repositório (precisa de nginx/ e de vendor/cdmoj).
FROM nginx:1.30.5-alpine@sha256:0985e772fb9f729e6fa0980da05fca5d9c468e870eed43071545afa9d2e27d94
COPY nginx/moj.conf /etc/nginx/conf.d/default.conf
COPY nginx/moj-app.snippet /etc/nginx/moj-app.snippet
COPY vendor/cdmoj/web /moj/cdmoj/web
COPY vendor/cdmoj/docs /moj/cdmoj/docs
