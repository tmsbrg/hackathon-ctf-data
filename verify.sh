#!/usr/bin/env bash
# Smoke-test that all CTF secrets are discoverable via rga
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
DUMP="$ROOT/smb_dump"
CACHE="${RGA_CACHE:-/tmp/rga-ctf-cache}"

if [[ ! -d "$DUMP" ]]; then
  echo "Run ./generate_ctf.sh first"
  exit 1
fi

RGA=(rga --rga-cache-path="$CACHE")

check() {
  local label="$1" pattern="$2"
  if "${RGA[@]}" -q "$pattern" "$DUMP/"; then
    echo "OK  $label"
  else
    echo "FAIL $label (pattern: $pattern)"
    exit 1
  fi
}

echo "Checking secrets in $DUMP ..."
check "VPN wachtwoord"     'VeloCity-VPN-9kLm2!'
check "DB password (zip)"  'PgProd_Nordwind_7xK!mQ'
check "AWS key"            'AKIA4NORDWIND9SECRET'
check "GitHub PAT"         'ghp_NwL0g1st1cs_BreachSim_a8f3c2'
check "BSN Sophie (pdf)"   '987654329'
check "BSN Pieter (zip)"   '111222333'
check "Shanghai 密码"       'Nordwind_Shanghai_密钥_8842'
check "Stripe key (docx)"  'sk_live_NwStripe2024xK9mP2qR7'
check "Final flag (pdf)"   'FLAG\{smb_ripgrep_trufflehog_master\}'

COUNT=$(find "$DUMP" -type f | wc -l)
echo ""
echo "All 9 checks passed ($COUNT files in dump)."
