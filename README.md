# MOJ do PET

Instância do [MOJ](https://github.com/cd-moj/cdmoj) mantida pelo PET Engenharia de Computação da
Ufes, em `moj.pet.inf.ufes.br`. Serve o treino aberto e as provas do Topcom e pode ser usada
depois nas disciplinas de programação.

O código do MOJ não é alterado aqui. Ele entra como submódulo em `vendor/`, fixado num commit
do upstream (`cdmoj` e `mojtools`). Este repositório guarda só o que é nosso: o nginx, o compose
da stack e o CI.

## Como vai ao ar

Cada merge na `main` que mexe em `vendor/`, `nginx/` ou no workflow faz o CI construir duas
imagens e publicá-las no GHCR:

- `server`: o cdmoj empacotado pelo `Containerfile` dele. Roda como `api` e como `judged`.
- `web`: o nginx com os arquivos estáticos e o vhost de `nginx/`.

O job `implanta` grava o digest novo no `docker-compose.prod.yml`, e o Portainer da VM aplica a
mudança em até 1 minuto. Para voltar uma versão, basta dar `git revert` no commit `deploy:`.

## Atualizar o MOJ

O upstream muda quase todo dia. Para atualizar, mova os submódulos para o commit novo num PR:

```bash
git -C vendor/cdmoj fetch && git -C vendor/cdmoj checkout origin/master
git -C vendor/mojtools fetch && git -C vendor/mojtools checkout origin/master
git add vendor && git commit -m "Atualiza o MOJ para <commit>"
```

Perto de uma prova, a versão fica congelada: nada de atualização nas duas semanas anteriores.

## Detalhes da stack

- **IP real.** A trava por IP da prova usa o IP da conexão, e aqui a conexão vem do Traefik. O
  nginx aceita o `X-Forwarded-For` só da rede `traefik` (172.31.0.0/16), e de qualquer outra
  origem o cabeçalho é ignorado. Se a rede `traefik` da VM for recriada com outra faixa, é
  preciso ajustar o `set_real_ip_from` em `nginx/moj.conf`.
- **Julgamento.** Não roda na VM. Os juízes são máquinas à parte com o agente do
  [cdjudge](https://github.com/cd-moj/cdjudge), que buscam os jobs na API pela internet
  (`vendor/cdmoj/server/judge-gw/PULL.md`).
- **Desligados por enquanto:** o pool de workers (`MOLDE_DISABLE`), o leitor rápido das rotas
  quentes (`PORTEIRO_DISABLE`) e o alimentador do telão (`ANIMEITOR_FEED_DISABLE`). Os dois
  primeiros só ajudam com milhares de acessos e exigem os snippets de rota no nginx.
- **Dados** ficam nos volumes `moj_run`, `moj_contests`, `moj_problems` e `moj_news`.
