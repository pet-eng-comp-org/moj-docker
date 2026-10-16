# Imagem "judge" do moj-docker: o agente do cdjudge com a jaula e os compiladores dentro.
# MOJ_SYSROOT é o rootfs das linguagens, construído do vendor/mojtools/sysroot/Containerfile
# (imagem "sysroot" deste repositório); ele vai inteiro para /opt/moj-sysroot e a jaula (bwrap)
# roda as soluções dentro dele. Contexto de build = a raiz do repositório.
ARG MOJ_SYSROOT=moj-docker/sysroot
FROM ${MOJ_SYSROOT} AS sysroot

FROM debian:trixie-slim
# runtime da jaula e do agente (cdjudge/README.md, "Dependências"); g++ compila o corretor e o
# árbitro dos problemas fora da jaula
RUN apt-get update && apt-get install -y --no-install-recommends \
      bash bubblewrap time coreutils util-linux bc make diffutils gawk grep sed tar gzip \
      curl ca-certificates jq git procps g++ \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -u 1000 juiz
COPY --from=sysroot / /opt/moj-sysroot
COPY --chown=juiz:juiz vendor/cdjudge /home/juiz/judge
COPY --chown=juiz:juiz vendor/mojtools /home/juiz/mojtools
COPY imagens/judge/moj-docker-judge /usr/local/bin/moj-docker-judge
RUN install -d -o juiz -g juiz /home/juiz/cache
USER juiz
WORKDIR /home/juiz/judge
ENV MOJ_API=http://web/api/v1 \
    WORKER_TOKEN_FILE=/run/moj/worker.token \
    MOJTOOLS_DIR=/home/juiz/mojtools \
    JUDGE_CACHE=/home/juiz/cache/problems \
    CAGE_ROOT=/opt/moj-sysroot \
    CAPABILITY=pos \
    HEARTBEAT_SECS=3
ENTRYPOINT ["/usr/local/bin/moj-docker-judge"]
