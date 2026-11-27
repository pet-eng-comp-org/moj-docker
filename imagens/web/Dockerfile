# Imagem "web" do moj-docker: o nginx com o vhost e os arquivos estáticos do cdmoj.
# Contexto de build = a raiz do repositório (precisa de imagens/web e de vendor/cdmoj).
FROM nginx:1.30.7-alpine@sha256:caf4e1e032a20f9c3c5e28fc7f25ffd768ad8677b4975c54193075997b3a97e3
COPY imagens/web/moj.conf /etc/nginx/conf.d/default.conf
COPY imagens/web/moj-app.snippet /etc/nginx/moj-app.snippet
COPY imagens/web/20-moj-real-ip.sh /docker-entrypoint.d/20-moj-real-ip.sh
COPY vendor/cdmoj/web /moj/cdmoj/web
COPY vendor/cdmoj/docs /moj/cdmoj/docs
