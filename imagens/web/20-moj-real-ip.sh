#!/bin/sh
# Gera /etc/nginx/moj-real-ip.conf a partir de MOJ_TRUSTED_PROXIES (redes separadas por espaço
# ou vírgula, ex.: "172.31.0.0/16"). Vazio = nenhum proxy confiável: vale o IP da conexão.
set -eu
OUT=/etc/nginx/moj-real-ip.conf
rm -f "$OUT"
redes=$(printf '%s' "${MOJ_TRUSTED_PROXIES:-}" | tr ',' ' ')
[ -n "$(printf '%s' "$redes" | tr -d ' ')" ] || exit 0
for r in $redes; do
  case "$r" in
    *[!0-9a-fA-F.:/]*) echo "MOJ_TRUSTED_PROXIES: rede inválida '$r'" >&2; exit 1 ;;
  esac
  echo "set_real_ip_from $r;"
done > "$OUT"
printf 'real_ip_header X-Forwarded-For;\nreal_ip_recursive on;\n' >> "$OUT"
echo "moj: X-Forwarded-For aceito de: $redes"
