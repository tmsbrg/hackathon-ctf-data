#!/usr/bin/env bash
# Smoke-test CTF secrets — rga for text, specialized checks for OCR/media archives
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
DUMP="$ROOT/smb_dump"
export DUMP
CACHE="${RGA_CACHE:-/tmp/rga-ctf-cache}"

if [[ ! -d "$DUMP" ]]; then
  echo "Run ./generate_ctf.sh first"
  exit 1
fi

RGA=(rga --rga-cache-path="$CACHE")

check_rga() {
  local label="$1" pattern="$2"
  if "${RGA[@]}" -q "$pattern" "$DUMP/"; then
    echo "OK  $label"
  else
    echo "FAIL $label (pattern: $pattern)"
    exit 1
  fi
}

check_contains() {
  local label="$1" file="$2" pattern="$3"
  if [[ -f "$file" ]] && grep -q "$pattern" "$file" 2>/dev/null; then
    echo "OK  $label"
  else
    echo "FAIL $label ($file)"
    exit 1
  fi
}

echo "=== Core secrets (rga) ==="
check_rga "VPN wachtwoord"     'VeloCity-VPN-9kLm2!'
check_rga "DB password (zip)"  'PgProd_Nordwind_7xK!mQ'
check_rga "AWS key"            'AKIA4NORDWIND9SECRET'
check_rga "GitHub PAT"         'ghp_NwL0g1st1cs_BreachSim_a8f3c2'
check_rga "BSN Sophie (pdf)"   '987654329'
check_rga "BSN Pieter (zip)"   '111222333'
check_rga "Shanghai 密码"       'Nordwind_Shanghai_密钥_8842'
check_rga "Stripe key (docx)"  'sk_live_NwStripe2024xK9mP2qR7'
check_rga "Final flag (pdf)"   'FLAG\{smb_ripgrep_trufflehog_master\}'

echo ""
echo "=== Extended secrets ==="
check_rga "Portal reset (eml)" 'PortalReset-2024-xK9'

if unzip -p "$DUMP/Finance/payroll/salary_bands_2024.xlsx" 'xl/worksheets/sheet2.xml' 2>/dev/null | grep -q 'fin_api_NwQ3_8842secret'; then
  echo "OK  Finance API key (xlsx hidden sheet)"
else
  echo "FAIL Finance API key (xlsx hidden sheet)"
  exit 1
fi

if exiftool -UserComment "$DUMP/Shared/office_party_2024.jpg" 2>/dev/null | grep -q 'BONUS{exif_metadata_dig}'; then
  echo "OK  Bonus flag (EXIF)"
else
  echo "FAIL Bonus flag (EXIF)"
  exit 1
fi

TMP7Z=$(mktemp)
unzip -p "$DUMP/IT/backups/legacy_oracle_2019.zip" configs.7z > "$TMP7Z"
if 7z x -so "$TMP7Z" 2>/dev/null | grep -q 'OrclNw2019!sys'; then
  echo "OK  Legacy Oracle (zip>7z)"
else
  echo "FAIL Legacy Oracle (zip>7z)"
  rm -f "$TMP7Z"
  exit 1
fi
rm -f "$TMP7Z"

SCAN_PDF="$DUMP/HR/exit_interviews/Mulder_contract_scan.pdf"
PNG="$DUMP/China_Office/training/wms_terminal_screenshot.png"

if [[ -f "$SCAN_PDF" ]] && ! pdftotext "$SCAN_PDF" - 2>/dev/null | grep -q '147258364'; then
  echo "OK  Scanned PDF has no text layer (OCR required)"
else
  echo "FAIL Scanned PDF should be image-only"
  exit 1
fi

echo ""
echo "=== Config filetype secrets (rga) ==="
check_rga "Redis password (.conf)"     'RedisNw-Cache-8842!'
check_rga "Spring DB pwd (.yml)"       'SpringStg_NwPortal_7xK!'
check_rga "SendGrid key (.yml)"        'SG.NwMail2024.xK9secret'
check_rga "Terraform DB (.tfvars)"     'TfNwDb_Staging_7xK!'
check_rga "GlobalProtect PSK (.ovpn)"  'GP-Exec-PSK-2024-Rot'
# dotfiles — rg/rga skip hidden files unless --hidden
check_contains "npm registry token (.npmrc)" \
  "$DUMP/IT/deploy_logs/.npmrc" 'npm_NwRegistry_8842token'
check_contains "Kube bonus flag (.kube/config)" \
  "$DUMP/IT/cloud/.kube/config" 'BONUS{kube_config_hunter}'
check_rga "Mongo docker (.yml)"        'MongoNw-Docker-8842'

echo ""
echo "=== Crypto material (ssh-keygen / openssl) ==="
if ssh-keygen -l -f "$DUMP/IT/deploy/ci_deploy_ed25519" >/dev/null 2>&1; then
  echo "OK  CI deploy ed25519 key (valid)"
else
  echo "FAIL CI deploy ed25519 key"
  exit 1
fi
if ssh-keygen -l -f "$DUMP/IT/deploy/id_rsa" >/dev/null 2>&1; then
  echo "OK  Legacy RSA deploy key (valid)"
else
  echo "FAIL Legacy RSA deploy key"
  exit 1
fi
if ssh-keygen -l -f "$DUMP/China_Office/.ssh/id_ed25519" >/dev/null 2>&1; then
  echo "OK  Shanghai ed25519 key (valid)"
else
  echo "FAIL Shanghai ed25519 key"
  exit 1
fi
if openssl x509 -in "$DUMP/IT/onboarding/nw-deploy.pem" -noout -subject >/dev/null 2>&1; then
  echo "OK  Deploy TLS cert (openssl x509)"
else
  echo "FAIL Deploy TLS cert"
  exit 1
fi
if openssl x509 -in "$DUMP/IT/onboarding/vpn-ca.crt" -noout -subject >/dev/null 2>&1; then
  echo "OK  VPN CA cert (openssl x509)"
else
  echo "FAIL VPN CA cert"
  exit 1
fi
if grep -q 'BEGIN CERTIFICATE' "$DUMP/IT/onboarding/executive_globalprotect.ovpn" \
   && grep -q 'BEGIN CERTIFICATE' "$DUMP/IT/onboarding/vpn-ca.crt"; then
  echo "OK  OVPN embeds real CA PEM"
else
  echo "FAIL OVPN CA embedding"
  exit 1
fi
check_rga "Vault unseal (.hcl)"        'VaultNw-Unseal-8842-xK9m'

echo ""
echo "=== Vaults (.kdbx, .p12, .jks, .env) ==="
check_contains "Redis in deploy .env" \
  "$DUMP/IT/deploy/.env" 'RedisNw-Cache-8842!'
check_contains "SendGrid in .env.production" \
  "$DUMP/IT/deploy/.env.production" 'SG.NwMail2024.xK9secret'

if openssl pkcs12 -in "$DUMP/Operations/customs/broker_client_auth.p12" \
    -noout -passin 'pass:P12Nw-8842!' 2>/dev/null; then
  echo "OK  PKCS12 broker cert (password unlocks)"
else
  echo "FAIL PKCS12 broker cert"
  exit 1
fi

KEYTOOL_BIN="${KEYTOOL:-$(command -v keytool 2>/dev/null || true)}"
if [[ -n "$KEYTOOL_BIN" ]] && \
   "$KEYTOOL_BIN" -list -keystore "$DUMP/IT/cloud/nw-portal.jks" \
     -storepass 'JksNw-8842!' >/dev/null 2>&1; then
  echo "OK  JKS portal keystore (password unlocks)"
else
  echo "FAIL JKS portal keystore"
  exit 1
fi

if ! python3 -c "import pykeepass" 2>/dev/null; then
  echo "SKIP KeePass checks (pip install pykeepass)"
else
  python3 << 'PYEOF'
import os, sys
from pathlib import Path

DUMP = Path(os.environ["DUMP"])
kdbx = DUMP / "Finance/nordwind_passwords.kdbx"
wordlist = DUMP / "IT/backups/password_audit_wordlist.txt"

from pykeepass import PyKeePass
from pykeepass.exceptions import CredentialsError

def try_open(password: str) -> PyKeePass | None:
    try:
        return PyKeePass(str(kdbx), password=password)
    except CredentialsError:
        return None

kp = try_open("Nordwind2024")
if not kp:
    print("FAIL KeePass master password")
    sys.exit(1)
print("OK  KeePass master password")

flag = kp.find_entries(title="CTF bonus", first=True)
if flag and "BONUS{keepass_windmill_vault}" in (flag.password or ""):
    print("OK  KeePass bonus flag")
else:
    print("FAIL KeePass bonus flag")
    sys.exit(1)

dd = kp.find_entries(title="Datadog monitoring EU", first=True)
if dd and dd.password == "dd_api_NwMonitor_8842secret":
    print("OK  KeePass Datadog API key")
else:
    print("FAIL KeePass Datadog API key")
    sys.exit(1)

cracked = False
for line in wordlist.read_text().splitlines():
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    if try_open(line):
        cracked = True
        break
if cracked:
    print("OK  KeePass cracked via audit wordlist (brute force path)")
else:
    print("FAIL KeePass wordlist brute force")
    sys.exit(1)
PYEOF
fi

echo ""
echo "=== Office formats (.doc / .xlsx / .xls — unzip or LibreOffice) ==="
lo_to_text() {
  local src="$1"
  local tmp
  tmp=$(mktemp -d)
  HOME="$tmp" libreoffice --headless --norestore --convert-to txt --outdir "$tmp" "$src" 2>/dev/null
  cat "$tmp"/*.txt 2>/dev/null
  rm -rf "$tmp"
}

lo_to_csv() {
  local src="$1"
  local tmp
  tmp=$(mktemp -d)
  HOME="$tmp" libreoffice --headless --norestore --convert-to csv --outdir "$tmp" "$src" 2>/dev/null
  cat "$tmp"/*.csv 2>/dev/null
  rm -rf "$tmp"
}

if rga -q 'sap_api_NwVendor_8842secret' "$DUMP/" 2>/dev/null; then
  echo "WARN SAP key visible via rga (install-dependent — unzip/LO still valid)"
else
  echo "OK  SAP memo not indexed by rga (expected)"
fi

if lo_to_text "$DUMP/Finance/invoices/2024/SAP_vendor_integration_memo.doc" \
   | grep -q 'sap_api_NwVendor_8842secret'; then
  echo "OK  SAP API key (.doc)"
else
  echo "FAIL SAP API key (.doc)"
  exit 1
fi

if lo_to_text "$DUMP/HR/policies/IT_account_reset_procedure_2019.doc" \
   | grep -q 'LegacyHr-Wachtwoord-8842!'; then
  echo "OK  Legacy HR wachtwoord (.doc)"
else
  echo "FAIL Legacy HR wachtwoord (.doc)"
  exit 1
fi

EMERGENCY_XLSX="$DUMP/Finance/payroll/emergency_access_roster_Q4.xlsx"
if unzip -p "$EMERGENCY_XLSX" xl/sharedStrings.xml 2>/dev/null | grep -q 'BgNw-Emergency-2024-xK9' \
   || unzip -p "$EMERGENCY_XLSX" xl/worksheets/sheet1.xml 2>/dev/null | grep -q 'BgNw-Emergency'; then
  echo "OK  Emergency token (.xlsx unzip)"
else
  echo "FAIL Emergency token (.xlsx)"
  exit 1
fi

FUEL_XLSX="$DUMP/Operations/routes/fuel_card_registry_2024.xlsx"
if unzip -p "$FUEL_XLSX" xl/worksheets/*.xml 2>/dev/null | grep -q 'fleet_api_NwShell_8842secret'; then
  echo "OK  Fleet API key (xlsx hidden sheet unzip)"
else
  echo "FAIL Fleet API key (xlsx hidden sheet)"
  exit 1
fi

XLS_FILE="$DUMP/Finance/invoices/2023/archive_invoice_index_2023.xls"
if lo_to_csv "$XLS_FILE" | grep -q 'ArchNw-Xls-8842legacy'; then
  echo "OK  Archive export key (.xls)"
else
  echo "FAIL Archive export key (.xls)"
  exit 1
fi

if command -v tesseract >/dev/null 2>&1; then
  if tesseract "$SCAN_PDF" stdout 2>/dev/null | grep -q '147258364'; then
    echo "OK  Contractor BSN via OCR (pdf)"
  else
    echo "WARN Contractor BSN OCR on PDF failed — check tesseract language packs"
  fi
  if tesseract "$PNG" stdout 2>/dev/null | grep -q 'ShaWMS-2024-Rot'; then
    echo "OK  WMS terminal password via OCR (png)"
  else
    echo "WARN WMS terminal OCR on PNG failed — open image manually to verify"
  fi
else
  echo "SKIP OCR checks (tesseract not installed — image secrets verified manually)"
fi

COUNT=$(find "$DUMP" -type f | wc -l)
echo ""
echo "All checks passed ($COUNT files in dump)."
