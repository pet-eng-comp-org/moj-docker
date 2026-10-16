# moj-docker

O [MOJ](https://github.com/cd-moj/cdmoj) em containers Docker: a plataforma, o site e o juiz
sobem com um `docker compose up`.

## Sumário

- [O que é o MOJ](#o-que-é-o-moj)
- [Por que o moj-docker](#por-que-o-moj-docker)
- [Requisitos](#requisitos)
- [Início rápido](#início-rápido)
- [Como funciona](#como-funciona)
- [Em produção, atrás do Traefik](#em-produção-atrás-do-traefik)
- [O juiz: no container ou na máquina](#o-juiz-no-container-ou-na-máquina)
- [Variáveis](#variáveis)
- [Construir as imagens](#construir-as-imagens)
- [Atualizar o MOJ](#atualizar-o-moj)
- [Problemas conhecidos](#problemas-conhecidos)
- [Quem usa](#quem-usa)
- [Licença](#licença)

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

O `cdmoj` já traz um Containerfile e units do podman para a plataforma. Faltava subir tudo,
juiz incluído, num lugar que só tem Docker, e sem passos manuais. O moj-docker acrescenta:

- **Docker Compose** com os quatro serviços, e um arquivo extra para rodar atrás do Traefik;
- **a primeira subida automática**: o treino, a primeira conta de administrador e o token dos
  juízes, que no MOJ nascem à mão (`vendor/cdmoj/docs/ADMIN.md`, seções 2 e 5);
- **o juiz num container**, com os compiladores dentro e sem `--privileged`;
- **o IP real do visitante** atrás de um proxy, que a trava por IP das provas exige;
- **imagens publicadas** no GHCR a cada mudança, com deploy contínuo pelo digest.

O código do MOJ não é alterado: os três repositórios entram como submódulos em `vendor/`,
fixados num commit testado. O modelo é o [boca-docker](https://github.com/rlaiola/boca-docker),
do Prof. Rodrigo Laiola Guimarães (Ufes), que faz o mesmo pelo BOCA.

## Requisitos

- Docker com o plugin Compose (Docker Desktop ou Docker Engine);
- Linux x86-64 para o juiz (o rootfs dos compiladores é amd64);
- Git, só para construir as imagens.

## Início rápido

1. Baixe os arquivos `docker-compose.yml` e `docker-compose.local.yml` para uma pasta.
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

O juiz leva alguns minutos na primeira vez: ele mede o tempo-limite de cada problema antes de
julgar envios para ele (a "calibração"). Para parar, use o mesmo comando com `down` no lugar de
`up -d`. Os dados ficam nos volumes `moj_*` e sobrevivem ao `down`; `down -v` apaga tudo.

Para cadastrar problemas e montar provas, o guia do organizador está em `/treino/criar/` na
própria plataforma.

## Como funciona

| Serviço | Imagem | O que faz |
|---|---|---|
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

## Em produção, atrás do Traefik

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
|---|---|---|
| Instalação | nenhuma | `vendor/cdjudge/README.md` (`make install`) |
| Limite de memória da solução | apurado pela memória medida depois da execução | rígido: o cgroup mata a solução no instante em que passa |
| Indicado para | testes, treino, aulas | provas |

A diferença vem da jaula do `mojtools`: o limite rígido usa um gerenciador `systemd --user`
(`systemd-run --user --scope -p MemoryMax`), que não existe dentro de um container comum. O
container do juiz tem um teto de memória próprio (`MOJ_JUDGE_MEM`, padrão 4 GB) para proteger o
resto da máquina.

Para o juiz na máquina, o rootfs dos compiladores pode sair da imagem `sysroot` deste
repositório:

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

O rootfs do juiz traz o núcleo do `mojtools`: C, C++, Java, Kotlin e Python (CPython e PyPy),
que são as linguagens da Maratona SBC. O `mojtools` sabe instalar outras (Pascal, C#, Go, Rust,
Haskell, JavaScript, OCaml, Prolog), mas elas deixam a imagem do juiz com 6 GB em vez de 3.
Para incluí-las, construa o `sysroot` sem o `--build-arg PKGS=` (ver
[Construir as imagens](#construir-as-imagens)).

## Variáveis

| Variável | Padrão | Para quê |
|---|---|---|
| `MOJ_ADMIN` | `admin.admin` | Login do primeiro administrador (tem de terminar em `.admin`). Só vale na primeira subida. |
| `MOJ_ADMIN_PASSWORD` | gerada e mostrada no log | Senha dele. Só vale na primeira subida. |
| `MOJ_PORT` | `8080` | Porta do site no `docker-compose.local.yml`. |
| `MOJ_HOST` | | Domínio, no `docker-compose.traefik.yml`. |
| `MOJ_TRUSTED_PROXIES` | | Redes de proxy confiáveis (separadas por espaço ou vírgula). |
| `MOJ_JUDGE_MEM` | `4g` | Teto de memória do container do juiz. |
| `MOJ_JUDGE_PARTITION` | `off` | Como dividir as CPUs do juiz entre envios simultâneos (`cpus:1` = uma CPU por envio). |
| `MOJ_JUDGE_HOST` | `moj-docker` | Nome do juiz no painel. |
| `TRAEFIK_NETWORK`, `TRAEFIK_ENTRYPOINT`, `TRAEFIK_CERTRESOLVER` | `traefik`, `websecure`, `le` | Como o Traefik da máquina está configurado. |

## Construir as imagens

```sh
git clone --recurse-submodules https://github.com/pet-eng-comp-org/moj-docker.git
cd moj-docker
# server: primeiro a imagem do cdmoj, depois a camada do moj-docker
cp vendor/cdmoj/deploy/.containerignore vendor/.dockerignore
docker build -t moj-docker/server-base -f vendor/cdmoj/deploy/Containerfile vendor
rm vendor/.dockerignore
docker build -t moj-docker/server -f imagens/server/Dockerfile .
docker build -t moj-docker/web -f imagens/web/Dockerfile .
# judge: primeiro o rootfs dos compiladores (demora: são uns 2 GB de toolchains)
docker build --build-arg PKGS= -t moj-docker/sysroot -f vendor/mojtools/sysroot/Containerfile vendor/mojtools/sysroot
docker build -t moj-docker/judge -f imagens/judge/Dockerfile .
```

Para usar as imagens locais, crie um arquivo que troque o `image:` de cada serviço e junte-o aos
outros com mais um `-f`.

## Atualizar o MOJ

O upstream muda quase todo dia. Para atualizar, mova os submódulos para o commit novo num PR:

```sh
for r in cdmoj mojtools cdjudge; do git -C vendor/$r fetch && git -C vendor/$r checkout origin/master; done
git add vendor && git commit -m "Atualiza o MOJ"
```

O CI constrói as imagens no PR. Depois do merge, o job `implanta` grava os digests novos no
`docker-compose.yml`, e o Portainer de quem acompanha o repositório aplica a mudança em até
um minuto. Para voltar, basta dar `git revert` no commit `deploy:`. Perto de uma prova, a
versão fica congelada.

## Problemas conhecidos

- **Memória no juiz em container:** o limite por solução não é rígido (ver acima).
- **Caminhos rápidos desligados:** o pool de workers e o leitor rápido das rotas mais acessadas
  (`MOLDE_DISABLE`, `PORTEIRO_DISABLE`) exigem trechos de configuração no nginx que ainda não
  estão aqui. Só fazem diferença com milhares de acessos simultâneos.
- **Telão do Animeitor desligado** (`ANIMEITOR_FEED_DISABLE`).
- **Cadastro no treino:** no MOJ, ele é confirmado por um bot do Telegram, que ainda não está no
  compose. Até lá, as contas são criadas pelo administrador.
- **Rotinas diárias** do cdmoj (limpeza de relatórios antigos e de processos órfãos) ainda não
  rodam.

## Quem usa

- **PET Engenharia de Computação da Ufes**, em <https://moj.pet.inf.ufes.br>: treino e provas do
  Topcom, o torneio de programação da Ufes.

## Licença

Os arquivos deste repositório (composes, Dockerfiles, scripts e documentação) estão sob a
licença MIT (`LICENSE`). Os submódulos em `vendor/` são dos seus autores e seguem as licenças
dos repositórios originais.
