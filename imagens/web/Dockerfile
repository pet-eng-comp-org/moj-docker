# Imagem "web" do moj-docker: o nginx com o vhost e os arquivos estáticos do cdmoj.
# Contexto de build = a raiz do repositório (precisa de imagens/web e de vendor/cdmoj).
FROM nginx:1.31.0-alpine@sha256:2f07d83bf561b506400dc183b1b2003803e39efbd22451f848adaba14d28c7c7
COPY imagens/web/moj.conf /etc/nginx/conf.d/default.conf
COPY imagens/web/moj-app.snippet /etc/nginx/moj-app.snippet
COPY imagens/web/20-moj-real-ip.sh /docker-entrypoint.d/20-moj-real-ip.sh
COPY vendor/cdmoj/web /moj/cdmoj/web
COPY vendor/cdmoj/docs /moj/cdmoj/docs
