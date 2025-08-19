#!/usr/bin/env bash
set -euo pipefail

VERSAO_FILE="${PATH_VERSAO_FILE:-Atual/versao_release.txt}"
URL_BASE_VERSAO40="${URL_BASE_VERSAO40}"
URL_BASE_RELEASE40="${URL_BASE_RELEASE40}"
LOOKBACK_DAYS_VERSION=21
DEBUG_URLS="${DEBUG_URLS:-false}"

exists_url () { curl -k -sS -I --fail "$1" >/dev/null 2>&1; }

read_current () {
  CUR_VER="$(grep -E '^Versao atual:' "$VERSAO_FILE" | awk -F': ' '{print $2}' | tr -d '[:space:]')"
  CUR_REL_LINE="$(grep -E '^Release atual:' "$VERSAO_FILE" | sed 's/^Release atual:[[:space:]]*//')"
  if [[ "$CUR_REL_LINE" == "VAZIO" || -z "$CUR_REL_LINE" ]]; then
    CUR_REL_LET=""; CUR_REL_DATE=""
  else
    CUR_REL_LET="$(echo "$CUR_REL_LINE" | awk '{print $1}')"
    CUR_REL_DATE="$(echo "$CUR_REL_LINE" | awk '{print $2}')"
  fi
}

is_letter_lmn () { [[ "${1:-}" =~ ^(L|M|N)$ ]]; }

next_letter () {
  local l="${1:-}"
  if [[ -z "$l" || "$l" == "VAZIO" ]]; then echo "A"; return; fi
  local c="${l:0:1}"
  if [[ "$c" == "Z" ]]; then echo "A"; else printf "\\$(printf '%03o' $(( $(printf '%d' "'$c") + 1 )) )"; fi
}

check_release_today () {
  local ver_ddmm="${CUR_VER:0:4}"
  local today_ddmm="$(date +%d%m)"
  local url="${URL_BASE_RELEASE40}${ver_ddmm}-a-${today_ddmm}.rar"

  [[ "$DEBUG_URLS" == "true" ]] && echo "[DEBUG] Testando RELEASE URL: $url" >&2

  if exists_url "$url"; then
    local letter="$(next_letter "$CUR_REL_LET")"
    local today_ddmmyy="$(date +%d%m%y)"
    echo "FOUND_RELEASE|${letter} ${today_ddmmyy}"
  else
    echo "NO_RELEASE"
  fi
}

find_new_version () {
  for ((i=0;i<=LOOKBACK_DAYS_VERSION;i++)); do
    local d=$(date -d "-$i day" +%d%m%y)
    local url="${URL_BASE_VERSAO40}${d}.rar"

    [[ "$DEBUG_URLS" == "true" ]] && echo "[DEBUG] Testando VERSAO URL: $url (data=$d)" >&2

    if exists_url "$url"; then
      [[ "$DEBUG_URLS" == "true" ]] && echo "[DEBUG] ✔ Encontrada VERSAO: $d" >&2
      echo "$d"
      return 0
    fi
  done
  echo ""
}

update_file () {
  local new_ver="$1"; local new_rel="$2"
  local v_line="Versao atual: ${CUR_VER}"
  local r_line="Release atual: ${CUR_REL_LINE:-VAZIO}"
  [[ -n "$new_ver" ]] && v_line="Versao atual: ${new_ver}"
  [[ -n "$new_rel" ]] && r_line="Release atual: ${new_rel}"
  { echo "$v_line"; echo "$r_line"; } > "$VERSAO_FILE"
}

main () {
  read_current
  echo >&2 "[INFO] Versao atual: $CUR_VER | Release atual: ${CUR_REL_LINE:-VAZIO}"

  rel_status="$(check_release_today)"
  if [[ "$rel_status" == FOUND_RELEASE* ]]; then
    new_rel="${rel_status#FOUND_RELEASE|}"
    if [[ "$CUR_REL_LINE" != "$new_rel" ]]; then
      update_file "" "$new_rel"
      echo "CHANGED|RELEASE|$CUR_REL_LINE|$new_rel"
      exit 0
    else
      echo "NOCHANGE|RELEASE_ALREADY_SET"; exit 0
    fi
  fi

  if is_letter_lmn "$CUR_REL_LET"; then
    echo >&2 "[INFO] Letra ${CUR_REL_LET} em L/M/N. Forcando checagem de NOVA VERSAO."
  else
    echo >&2 "[INFO] Sem release hoje. Checando NOVA VERSAO."
  fi

  new_ver="$(find_new_version)"
  if [[ -n "$new_ver" && "$new_ver" != "$CUR_VER" ]]; then
    update_file "$new_ver" "VAZIO"
    echo "CHANGED|VERSION|$CUR_VER|$new_ver"
    exit 0
  fi

  echo "NOCHANGE|NOTHING_FOUND"
}
main "$@"