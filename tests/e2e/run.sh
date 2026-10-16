#!/usr/bin/env bash
# Teste de ponta a ponta do moj-docker: sobe a stack inteira (juiz incluído), cadastra o problema
# de tests/e2e/problema, envia uma solução por linguagem e confere os veredictos.
#
#   tests/e2e/run.sh            usa as imagens com a tag "local" (docker buildx bake --load)
#   TAG=sha-<commit> tests/e2e/run.sh
#
# Roda num projeto e em volumes próprios (moj-e2e), sem tocar numa instância que já exista na
# máquina, e apaga tudo no fim. MANTER=1 deixa a stack de pé para olhar.
set -euo pipefail
cd "$(dirname "$0")"

export REGISTRY="${REGISTRY:-ghcr.io/pet-eng-comp-org/moj-docker}" TAG="${TAG:-local}"
export MOJ_PORT="${MOJ_PORT:-18080}" MOJ_ADMIN_PASSWORD="e2e-$RANDOM$RANDOM" MOJ_JUDGE_HOST=e2e
B="http://127.0.0.1:$MOJ_PORT/api/v1"
DC=(docker compose -p moj-e2e -f ../../docker-compose.yml -f ../../docker-compose.local.yml
    -f docker-compose.e2e.yml --profile juiz)
TMP="$(mktemp -d)"

fim() {
  local rc=$?
  if (( rc != 0 )); then
    echo "::group::logs da stack"; "${DC[@]}" logs --no-color --tail 80 || true; echo "::endgroup::"
  fi
  [[ "${MANTER:-}" == 1 ]] || "${DC[@]}" down -v --remove-orphans >/dev/null 2>&1 || true
  rm -rf "${TMP:?}"
  exit "$rc"
}
trap fim EXIT
trap 'exit 130' INT TERM

falha() { echo "FALHOU: $*" >&2; exit 1; }
ok() { jq -e '.success == true' >/dev/null || falha "$1"; }
api() { curl -sS -X "$1" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
          ${3:+--data-binary "$3"} "$B/$2"; }

echo ">> subindo a stack ($REGISTRY/*:$TAG)"
"${DC[@]}" up -d --quiet-pull
for _ in $(seq 60); do curl -sf "$B/" >/dev/null && break; sleep 2; done
curl -sf "$B/" >/dev/null || falha "a API não respondeu em 2 minutos"
curl -sf "http://127.0.0.1:$MOJ_PORT/treino/" >/dev/null || falha "o site não respondeu"

echo ">> login do administrador criado na primeira subida"
TOKEN="$(curl -sS -X POST -H 'Content-Type: application/json' \
  --data "$(jq -cn --arg p "$MOJ_ADMIN_PASSWORD" '{username:"admin.admin",password:$p}')" \
  "$B/auth/login?contest=treino" | jq -r '.token // empty')"
[[ -n "$TOKEN" ]] || falha "login do admin.admin"

echo ">> cadastrando o problema"
api POST orgs/create '{"name":"e2e","title":"Teste","public_allowed":true}' | ok "criar a org"
tar -czf "$TMP/soma.tgz" -C problema soma
jq -cn --rawfile t <(base64 -w0 "$TMP/soma.tgz") '{repo:"e2e",prob:"soma",tar_b64:$t}' > "$TMP/up.json"
api POST problems/upload "@$TMP/up.json" | ok "enviar o pacote"
# publicar indexa o problema e pede a calibração ao juiz
api POST problems/set-public '{"id":"e2e#soma","public":true}' | ok "publicar"
# a indexação roda em segundo plano: o envio só é aceito quando o problema aparece no treino
for _ in $(seq 60); do
  api GET treino/problems | jq -e 'any(.[]; .id == "e2e#soma")' >/dev/null && break
  sleep 2
done
api GET treino/problems | jq -e 'any(.[]; .id == "e2e#soma")' >/dev/null || falha "o problema não apareceu no treino"

echo ">> enviando as soluções"
ENVIOS=(soma.c soma.cpp Main.java Main.kt soma.py errada.c)
ESPERADO=(Accepted Accepted Accepted Accepted Accepted "Wrong Answer")
for arq in "${ENVIOS[@]}"; do
  jq -cn --arg n "$arq" --arg c "$(base64 -w0 "envios/$arq")" \
    '{problem_id:"e2e#soma",filename:$n,code_b64:$c}' > "$TMP/envio.json"
  api POST "submit?contest=treino" "@$TMP/envio.json" | ok "enviar $arq"
done

echo ">> esperando o juiz (calibração e julgamento)"
# history: hora:login:problema:linguagem:veredicto:hora:id, um envio por linha, na ordem do envio
for _ in $(seq 90); do
  api GET "contest/history?contest=treino" > "$TMP/history"
  pendentes=$(grep -c 'Not Answered' "$TMP/history" || true)
  total=$(grep -c . "$TMP/history" || true)
  (( total == ${#ENVIOS[@]} && pendentes == 0 )) && break
  sleep 10
done
cat "$TMP/history"
(( pendentes == 0 )) || falha "$pendentes envio(s) sem veredicto depois de 15 minutos"

echo ">> conferindo os veredictos"
# o history guarda os envios na ordem em que chegaram: a linha i é o envio i
mapfile -t VEREDICTOS < <(cut -d: -f5 "$TMP/history")
erros=0
for i in "${!ENVIOS[@]}"; do
  if [[ "${VEREDICTOS[$i]:-}" == "${ESPERADO[$i]}" ]]; then
    echo "   ok    ${ENVIOS[$i]}: ${ESPERADO[$i]}"
  else
    echo "   ERRO  ${ENVIOS[$i]}: esperado ${ESPERADO[$i]}, veio ${VEREDICTOS[$i]:-nada}"
    erros=$((erros + 1))
  fi
done
(( erros == 0 )) || falha "$erros veredicto(s) errado(s)"
echo ">> tudo certo"
