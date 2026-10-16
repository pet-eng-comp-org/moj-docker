# Imagem "server" do moj-docker: a imagem do cdmoj (construída do Containerfile dele, que é a
# base em MOJ_BASE) mais a primeira subida automática. Roda como "api" e como "judged".
ARG MOJ_BASE=moj-docker/server-base
FROM ${MOJ_BASE}
COPY imagens/server/moj-docker-init /opt/moj-docker/moj-docker-init
ENTRYPOINT ["/opt/moj-docker/moj-docker-init"]
CMD ["api"]
