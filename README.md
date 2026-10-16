# :balloon: moj-docker

[![CI][ci_badge]][ci_link]
[![Lint][lint_badge]][lint_link]
[![Limpa o cache][cache_badge]][cache_link]
[![Fecha inativos][stale_badge]][stale_link]

[![Versão][release_badge]][release_link]
[![Debian trixie][debian_badge]][debian_link]
[![Ubuntu noble][ubuntu_badge]][ubuntu_link]
[![amd64][arch_badge]][arch_link]
[![Licença MIT][license_badge]](LICENSE)

[ci_badge]: https://img.shields.io/github/actions/workflow/status/pet-eng-comp-org/moj-docker/publica-imagem.yml?branch=main&label=build%20%2B%20e2e&logo=github
[ci_link]: https://github.com/pet-eng-comp-org/moj-docker/actions/workflows/publica-imagem.yml
[lint_badge]: https://img.shields.io/github/actions/workflow/status/pet-eng-comp-org/moj-docker/lint.yml?label=lint&logo=github
[lint_link]: https://github.com/pet-eng-comp-org/moj-docker/actions/workflows/lint.yml
[cache_badge]: https://img.shields.io/github/actions/workflow/status/pet-eng-comp-org/moj-docker/limpa-cache.yml?label=limpa%20cache&logo=github
[cache_link]: https://github.com/pet-eng-comp-org/moj-docker/actions/workflows/limpa-cache.yml
[stale_badge]: https://img.shields.io/github/actions/workflow/status/pet-eng-comp-org/moj-docker/fecha-inativos.yml?label=fecha%20inativos&logo=github
[stale_link]: https://github.com/pet-eng-comp-org/moj-docker/actions/workflows/fecha-inativos.yml
[release_badge]: https://img.shields.io/github/v/release/pet-eng-comp-org/moj-docker?label=vers%C3%A3o
[release_link]: https://github.com/pet-eng-comp-org/moj-docker/releases/latest
[debian_badge]: https://img.shields.io/badge/servidor-debian%20trixie-A81D33.svg?logo=debian
[debian_link]: https://hub.docker.com/_/debian
[ubuntu_badge]: https://img.shields.io/badge/compiladores-ubuntu%20noble-E95420.svg?logo=ubuntu
[ubuntu_link]: https://hub.docker.com/_/ubuntu
[arch_badge]: https://img.shields.io/badge/arch-amd64-lightgray.svg?logo=docker&logoColor=white
[arch_link]: https://github.com/orgs/pet-eng-comp-org/packages?repo_name=moj-docker
[license_badge]: https://img.shields.io/github/license/pet-eng-comp-org/moj-docker?label=licen%C3%A7a

O [MOJ](https://github.com/cd-moj/cdmoj) em containers Docker: a plataforma, o site e o juiz
sobem com um `docker compose up`.

## Sumário

- [O que é o MOJ](#o-que-é-o-moj)
- [Por que o moj-docker](#por-que-o-moj-docker)
- [Requisitos](#requisitos)
- [Início rápido](#início-rápido)
- [Como funciona](#como-funciona)
- [Como implantar atrás do Traefik](#como-implantar-atrás-do-traefik)
- [O juiz: no container ou na máquina](#o-juiz-no-container-ou-na-máquina)
- [Configuração](#configuração)
- [Versões e tags das imagens](#versões-e-tags-das-imagens)
- [Como construir (para desenvolvimento)](#como-construir-para-desenvolvimento)
- [Como publicar](#como-publicar)
- [Como atualizar o MOJ](#como-atualizar-o-moj)
- [Como contribuir](#como-contribuir)
- [Problemas conhecidos](#problemas-conhecidos)
- [Quem usa](#quem-usa)
- [Licença](#licença)
- [Suporte](#suporte)

## O que é o MOJ

O MOJ é o juiz online que a Maratona SBC de Programação usa desde 2026. Ele junta treino livre
(um acervo de problemas aberto a qualquer pessoa), listas de exercícios e provas no formato da
Maratona: placar com congelamento, balões, impressão, clarifications, sedes e travas da máquina
do competidor. É desenvolvido pelo Prof. Bruno Ribas, em três repositórios:

- [`cdmoj`](https://github.com/cd-moj/cdmoj): a plataforma (API em bash atrás do nginx e o
  daemon que enfileira os julgamentos);
- [`mojtools`](https://github.com/cd-moj/mojtools): a jaula e as ferramentas de julgamento;
- [`cdjudge`](https://github.com/cd-moj/cdjudge): o agente que roda nas máquinas de juiz.

A instância pública fica em <https://moj.naquadah.com.br>. A documentação oficial está em
`vendor/cdmoj/docs/` e, na própria plataforma, em `/docs/`.

## Por que o moj-docker

Os autores implantam o MOJ numa máquina preparada à mão: nginx do sistema, a plataforma em
containers do podman, e cada juiz instalado na sua máquina com os compiladores. A primeira conta
de administrador, o treino e o token dos juízes também são criados à mão
(`vendor/cdmoj/docs/ADMIN.md`, seções 2 e 5). O moj-docker leva tudo isso para o Docker:

- Docker Compose com os quatro serviços, e um arquivo extra para rodar atrás do Traefik;
- a primeira subida automática: o treino, o primeiro administrador e o token dos juízes;
- o juiz num container, com os compiladores da Maratona dentro e sem `--privileged`;
- o IP real do visitante atrás de um proxy, que a trava por IP das provas exige;
- imagens publicadas no GHCR, testadas de ponta a ponta a cada mudança.

| Como os autores implantam | Com o moj-docker |
| :---: | :---: |
| ![Arquitetura original do MOJ](imgs/arquitetura-moj.png 'Arquitetura original do MOJ') | ![Arquitetura do moj-docker](imgs/arquitetura-moj-docker.png 'Arquitetura do moj-docker') |

O código do MOJ não é alterado: os três repositórios entram como submódulos em `vendor/`,
fixados num commit testado.

O projeto começou no PET Engenharia de Computação da Ufes, para hospedar o treino e as provas
do Topcom, o torneio de programação da Ufes. O modelo é o
[boca-docker](https://github.com/rlaiola/boca-docker), do Prof. Rodrigo Laiola Guimarães
(Ufes), que faz o mesmo pelo BOCA.

## Requisitos

- Docker com o plugin Compose (Docker Desktop ou Docker Engine);
- Linux x86-64 para o juiz (os compiladores são amd64);
- Git, só para construir as imagens.

## Início rápido

1. Baixe os arquivos da última versão para uma pasta:

   ```sh
   for f in docker-compose.yml docker-compose.local.yml; do
     curl -fsSLO "https://github.com/pet-eng-comp-org/moj-docker/releases/latest/download/$f"
   done
   ```

2. Suba tudo, juiz incluído:

   ```sh
   docker compose -f docker-compose.yml -f docker-compose.local.yml --profile juiz up -d
   ```

3. Pegue a senha do administrador, que é gerada na primeira subida:

   ```sh
   docker exec moj_api cat /data/run/secrets/senha-admin
   ```

4. Abra <http://localhost:8080/treino/> e entre como `admin.admin`. Para escolher a senha antes
   de subir, defina `MOJ_ADMIN_PASSWORD`.

Na primeira vez, o juiz leva alguns minutos para julgar o envio inicial de cada problema: antes,
ele mede o tempo-limite do problema (a "calibração"). Para parar, use o mesmo comando com `down`
no lugar de `up -d`. Os dados ficam nos volumes `moj_*` e sobrevivem ao `down`; `down -v` apaga
tudo.

Para cadastrar problemas e montar provas, o guia do organizador está em `/treino/criar/` na
própria plataforma.

## Como funciona

| Serviço | Imagem | O que faz |
| --- | --- | --- |
| `api` | `server` | A API do MOJ (scripts bash servidos pelo fcgiwrap num socket unix). Na primeira subida, cria o treino, o administrador e o token dos juízes. |
| `judged` | `server` | Recebe os envios e os põe na fila de julgamento, por ordem de prioridade (prova antes de treino). |
| `web` | `web` | O nginx: serve o site e passa `/api/v1/` para o socket da API. É o único serviço que recebe conexões de fora. |
| `judge` | `judge` | Busca envios na fila pela API, compila e roda cada um numa jaula (bwrap) e devolve o veredicto. |

Os quatro compartilham os volumes `moj_run` (socket, filas, sessões e segredos),
`moj_contests` (contests, contas e envios), `moj_problems` (cada problema é um repositório git) e
`moj_news`. A rede `internal` não tem saída para a internet: a API e o daemon só falam com o
nginx pelo socket, e o juiz fala com o nginx por essa rede.

O juiz é o único que mede tempo. Ele não precisa estar na mesma máquina: qualquer computador
com acesso à API pode ser juiz, e vários juízes dividem a mesma fila.

## Como implantar atrás do Traefik

Com um Traefik já rodando na máquina e um domínio apontando para ela:

```sh
export MOJ_HOST=moj.exemplo.br
export MOJ_TRUSTED_PROXIES=172.31.0.0/16   # docker network inspect traefik
docker compose -f docker-compose.yml -f docker-compose.traefik.yml up -d
```

`MOJ_TRUSTED_PROXIES` é obrigatória. A trava por IP das provas usa o IP da conexão, e atrás de um
proxy essa conexão vem sempre dele. O nginx passa a aceitar o `X-Forwarded-For` só quando ele vem
dessas redes; de qualquer outra origem o cabeçalho é ignorado, para ninguém se passar por outro
IP.

No Portainer, crie a stack a partir deste repositório com `docker-compose.yml` como arquivo
principal, `docker-compose.traefik.yml` como arquivo adicional e as variáveis acima no
ambiente da stack.

## O juiz: no container ou na máquina

| | Juiz no container (`--profile juiz`) | Juiz instalado na máquina |
| --- | --- | --- |
| Instalação | nenhuma | `vendor/cdjudge/README.md` (`make install`) |
| Limite de memória da solução | apurado pela memória medida depois da execução | rígido: o cgroup mata a solução no instante em que passa |
| Indicado para | testes, treino, aulas | provas |

A diferença vem da jaula do `mojtools`: o limite rígido usa um gerenciador `systemd --user`
(`systemd-run --user --scope -p MemoryMax`), que não existe dentro de um container comum. O
container do juiz tem um teto de memória próprio (`MOJ_JUDGE_MEM`, padrão 4 GB) para proteger o
resto da máquina.

Para o juiz na máquina, os compiladores podem sair da imagem `sysroot` deste repositório:

```sh
cid=$(docker create ghcr.io/pet-eng-comp-org/moj-docker/sysroot:latest true)
mkdir -p ~/moj-sysroot && docker export "$cid" | tar -x -C ~/moj-sysroot && docker rm "$cid"
```

e depois `make install ... INSTALL_FLAGS="--sysroot keep --token <arquivo>"` no `cdjudge`. O
token é o de `/data/run/secrets/worker.token` no container `moj_api`.

Por que o container do juiz precisa de `security_opt`: a jaula cria um user namespace, e o
Docker bloqueia isso por padrão. Testamos as permissões uma a uma: são necessárias
`seccomp=unconfined` (criar o namespace), `apparmor=unconfined` (montar a raiz da jaula) e
`systempaths=unconfined` (montar o `/proc` dela). O container não ganha capability nenhuma e
não roda como root.

### Linguagens

O juiz traz o núcleo do `mojtools`: C, C++, Java, Kotlin e Python (CPython e PyPy), que são as
linguagens da Maratona SBC. O `mojtools` sabe instalar outras (Pascal, C#, Go, Rust, Haskell,
JavaScript, OCaml, Prolog), mas elas deixam a imagem do juiz com 6 GB em vez de 3. Para
incluí-las, veja o alvo `sysroot` no `docker-bake.hcl`.

## Configuração

| Variável | Padrão | Para quê |
| --- | --- | --- |
| `MOJ_ADMIN` | `admin.admin` | Login do primeiro administrador (tem de terminar em `.admin`). Só vale na primeira subida. |
| `MOJ_ADMIN_PASSWORD` | gerada e mostrada no log | Senha dele. Só vale na primeira subida. |
| `MOJ_PORT` | `8080` | Porta do site no `docker-compose.local.yml`. |
| `MOJ_HOST` | | Domínio, no `docker-compose.traefik.yml`. |
| `MOJ_TRUSTED_PROXIES` | | Redes de proxy confiáveis (separadas por espaço ou vírgula). |
| `MOJ_JUDGE_MEM` | `4g` | Teto de memória do container do juiz. |
| `MOJ_JUDGE_PARTITION` | `off` | Como dividir as CPUs do juiz entre envios simultâneos (`cpus:1` = uma CPU por envio). |
| `MOJ_JUDGE_HOST` | `moj-docker` | Nome do juiz no painel. |
| `TRAEFIK_NETWORK`, `TRAEFIK_ENTRYPOINT`, `TRAEFIK_CERTRESOLVER` | `traefik`, `websecure`, `le` | Como o Traefik da máquina está configurado. |

## Versões e tags das imagens

As imagens ficam em `ghcr.io/pet-eng-comp-org/moj-docker/<imagem>`:

| Imagem | O que é |
| --- | --- |
| `server` | A plataforma (serviços `api` e `judged`). |
| `web` | O nginx com o site. |
| `judge` | O juiz, com os compiladores. |
| `server-base` | A imagem do MOJ como os autores a constroem, base da `server`. |
| `sysroot` | Os compiladores, base da `judge` e do juiz instalado na máquina. |

| Tag | O que aponta |
| --- | --- |
| `1.0.0`, `1.0` | Uma versão, com os commits do MOJ listados no [release](https://github.com/pet-eng-comp-org/moj-docker/releases). |
| `latest` | A última versão. |
| `sha-<commit>` | O build de um commit da `main` ou da `development`. O `docker-compose.yml` da `main` fixa o que está em produção pelo digest. |

## Como construir (para desenvolvimento)

```sh
git clone --recurse-submodules https://github.com/pet-eng-comp-org/moj-docker.git
cd moj-docker
docker buildx bake --load
```

O `docker-bake.hcl` descreve as cinco imagens e constrói cada base antes da imagem que depende
dela. A primeira vez demora: só os compiladores são uns 2 GB. As imagens saem com a tag `local`;
para usá-las, rode o teste de ponta a ponta, que já sobe a stack com elas:

```sh
tests/e2e/run.sh            # MANTER=1 deixa a stack de pé em http://localhost:18080
```

## Como publicar

Quem publica é o CI (`.github/workflows/publica-imagem.yml`):

- Num pull request, ele constrói as imagens, roda o lint e o teste de ponta a ponta, sem
  publicar nada.
- Na `development`, ele publica as imagens com a tag `sha-<commit>` e as testa.
- Na `main`, ele publica, testa e o job `implanta` grava os digests novos no
  `docker-compose.yml`. Quem acompanha esse arquivo (o Portainer do PET) aplica em até um minuto.
  Para voltar, basta dar `git revert` no commit `deploy:`.
- Numa versão, criada como release no GitHub com uma tag `X.Y.Z` na `main`, o
  `versiona.yml` dá as tags `X.Y.Z`, `X.Y` e `latest` às imagens que estão em produção naquele
  commit, sem reconstruir nada, e anexa ao release os arquivos do compose.

## Como atualizar o MOJ

O MOJ muda quase todo dia. Uma vez por mês o Dependabot abre um PR contra a `development` que
move os três submódulos para o commit mais novo do upstream, e o CI roda o teste de ponta a ponta
com eles. Para atualizar fora dessa data, faça o mesmo à mão:

```sh
for r in cdmoj mojtools cdjudge; do git -C vendor/$r fetch && git -C vendor/$r checkout origin/master; done
git add vendor && git commit -m "Atualiza o MOJ"
```

Perto de uma prova, a versão fica congelada: o PR do Dependabot espera a prova passar.

## Como contribuir

Veja o [CONTRIBUTING](CONTRIBUTING.md): o fluxo de branches, como testar e como rodar o lint
antes de abrir o PR.

## Problemas conhecidos

- Memória no juiz em container: o limite por solução não é rígido (ver
  [O juiz](#o-juiz-no-container-ou-na-máquina)).
- Caminhos rápidos desligados: o pool de workers e o leitor rápido das rotas mais acessadas
  (`MOLDE_DISABLE`, `PORTEIRO_DISABLE`) exigem trechos de configuração no nginx que ainda não
  estão aqui. Só fazem diferença com milhares de acessos simultâneos.
- Telão do Animeitor desligado (`ANIMEITOR_FEED_DISABLE`).
- Cadastro no treino: no MOJ, ele é confirmado por um bot do Telegram, que ainda não está no
  compose. Até lá, as contas são criadas pelo administrador.
- Rotinas diárias do MOJ (limpeza de relatórios antigos e de processos órfãos) ainda não
  rodam.

## Quem usa

<p align="left">
  <a href="https://pet.inf.ufes.br" target="_blank">
    <img src="https://upload.wikimedia.org/wikipedia/commons/1/18/Marca_Ufes_SVG.svg" alt="Ufes" height="100" hspace="10" align="top" />
  </a>
</p>

- **PET Engenharia de Computação da Ufes**, em <https://moj.pet.inf.ufes.br>: treino e provas do
  Topcom.

Usa o moj-docker? Abra um PR acrescentando a sua instituição aqui.

## Licença

Copyright (c) 2026 PET Engenharia de Computação, Universidade Federal do Espírito Santo (Ufes).

Os arquivos deste repositório (composes, Dockerfiles, scripts, testes e documentação) estão sob
a licença MIT ([LICENSE](LICENSE)). Os submódulos em `vendor/` são dos seus autores e seguem as
licenças dos repositórios originais.

## Suporte

Dúvidas e problemas do moj-docker vão nas
[issues](https://github.com/pet-eng-comp-org/moj-docker/issues). Falha de segurança, pelo relato
privado descrito no [SECURITY](SECURITY.md).
