# Como construir as imagens do moj-docker (docker buildx bake). Usado pelo CI e por quem
# constrói em casa:
#
#   docker buildx bake                  # as três imagens, com tag "local"
#   docker buildx bake judge --load     # só o juiz, carregado no Docker local
#
# server e judge partem de uma imagem base construída do código do MOJ (server-base, do
# Containerfile do cdmoj; sysroot, o rootfs dos compiladores do mojtools). O bake constrói a
# base antes e a entrega à imagem final pelo contexto "target:", sem precisar publicá-la.

variable "REGISTRY" {
  default = "ghcr.io/pet-eng-comp-org/moj-docker"
}

# tags separadas por vírgula (o CI passa sha-<commit> e, num release, a versão e latest)
variable "TAGS" {
  default = "local"
}

# cache de build: vazio em casa; o CI passa CACHE=gha (e CACHE_GRAVA=false onde só lê)
variable "CACHE" {
  default = ""
}

variable "CACHE_GRAVA" {
  default = true
}

function "cache_de" {
  params = [imagem]
  result = CACHE == "" ? [] : ["type=${CACHE},scope=${imagem}"]
}

function "cache_para" {
  params = [imagem]
  result = CACHE == "" || !CACHE_GRAVA ? [] : ["type=${CACHE},mode=max,scope=${imagem}"]
}

function "tags" {
  params = [imagem]
  result = [for t in split(",", TAGS) : "${REGISTRY}/${imagem}:${t}"]
}

group "default" {
  targets = ["server", "web", "judge"]
}

target "server-base" {
  # o .dockerignore deste contexto é um link para o .containerignore do cdmoj
  context    = "vendor"
  dockerfile = "cdmoj/deploy/Containerfile"
  tags       = tags("server-base")
  cache-from = cache_de("server-base")
  cache-to   = cache_para("server-base")
}

target "server" {
  context    = "."
  dockerfile = "imagens/server/Dockerfile"
  contexts = {
    moj-base = "target:server-base"
  }
  args = {
    MOJ_BASE = "moj-base"
  }
  tags       = tags("server")
  cache-from = cache_de("server")
  cache-to   = cache_para("server")
}

target "web" {
  context    = "."
  dockerfile = "imagens/web/Dockerfile"
  tags       = tags("web")
  cache-from = cache_de("web")
  cache-to   = cache_para("web")
}

target "sysroot" {
  context    = "vendor/mojtools/sysroot"
  dockerfile = "Containerfile"
  # só o núcleo do mojtools (C, C++, Java, Kotlin e Python, as linguagens da Maratona SBC); os
  # extras (Pascal, C#, Go, Rust, Haskell…) levam a imagem do juiz de 3 para 6 GB. Para tê-los,
  # passe em PKGS a lista do Containerfile: --set sysroot.args.PKGS="fp-compiler mono-mcs ..."
  args = {
    PKGS = ""
  }
  tags       = tags("sysroot")
  cache-from = cache_de("sysroot")
  cache-to   = cache_para("sysroot")
}

target "judge" {
  context    = "."
  dockerfile = "imagens/judge/Dockerfile"
  contexts = {
    moj-sysroot = "target:sysroot"
  }
  args = {
    MOJ_SYSROOT = "moj-sysroot"
  }
  tags       = tags("judge")
  cache-from = cache_de("judge")
  cache-to   = cache_para("judge")
}
