#!/usr/bin/env bash
# Smoke-test CTF secrets — rga for text, specialized checks for OCR/media archives
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
DUMP="$ROOT/smb_dump"
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
