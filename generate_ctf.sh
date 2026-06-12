#!/usr/bin/env bash
# Regenerate the Operation Windmill SMB dump CTF
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
DUMP="$ROOT/smb_dump"

echo "==> Cleaning old dump..."
rm -rf "$DUMP"
mkdir -p "$DUMP"

# ── helper: write markdown then convert ──────────────────────────────────────
mkdocx() { pandoc "$1" -o "$2"; }
mkpdf()  { pandoc "$1" -o "$2"; }

# ── directory tree ───────────────────────────────────────────────────────────
DIRS=(
  "_manifest"
  "HR/onboarding"
  "HR/policies"
  "HR/exit_interviews"
  "Finance/invoices/2023"
  "Finance/invoices/2024"
  "Finance/contracts"
  "Finance/payroll"
  "IT/onboarding"
  "IT/backups"
  "IT/cloud"
  "IT/deploy_logs"
  "IT/legacy"
  "IT/tickets"
  "Legal/contracts"
  "Legal/board"
  "Marketing/campaigns/2024"
  "Marketing/brand_assets"
  "Operations/routes"
  "Operations/warehouse"
  "Shared/meeting_notes"
  "Shared/recipes"
  "Shared/templates"
  "Shared/photos"
  "China_Office/reports"
  "China_Office/training"
  "Archives/2019"
  "Archives/2020"
  "Archives/2021"
)
for d in "${DIRS[@]}"; do mkdir -p "$DUMP/$d"; done

# ── manifest (looks like robocopy / rsync output) ────────────────────────────
cat > "$DUMP/_manifest/download_log.txt" << 'EOF'
================================================================================
 NORDWIND LOGISTICS BV — INCIDENT RESPONSE ARTIFACT
 SMB mirror job: 2024-11-03T02:14:33Z  operator: red-team-svc
 Source: \\nw-dc01\corp$, \\nw-dc01\finance$, \\nw-dc01\it$, \\nw-sh01\shared$
================================================================================

2024-11-03 02:14:33  START  robocopy \\nw-dc01\corp$\HR          -> ./HR
2024-11-03 02:18:01  OK     847 files  1.2 GB
2024-11-03 02:18:02  START  robocopy \\nw-dc01\finance$         -> ./Finance
2024-11-03 02:22:44  OK     1203 files  890 MB
2024-11-03 02:22:45  START  robocopy \\nw-dc01\it$              -> ./IT
2024-11-03 02:31:12  OK     562 files  2.4 GB
2024-11-03 02:31:13  START  robocopy \\nw-dc01\corp$\Legal       -> ./Legal
2024-11-03 02:33:00  OK     98 files   340 MB
2024-11-03 02:33:01  START  robocopy \\nw-dc01\corp$\Marketing   -> ./Marketing
2024-11-03 02:35:22  OK     411 files  620 MB
2024-11-03 02:35:23  START  robocopy \\nw-dc01\corp$\Operations -> ./Operations
2024-11-03 02:38:55  OK     334 files  180 MB
2024-11-03 02:38:56  START  robocopy \\nw-dc01\shared$          -> ./Shared
2024-11-03 02:40:10  OK     156 files  45 MB
2024-11-03 02:40:11  START  robocopy \\nw-sh01\shared$          -> ./China_Office
2024-11-03 02:41:33  OK     89 files   210 MB
2024-11-03 02:41:34  START  robocopy \\nw-dc01\archives$        -> ./Archives
2024-11-03 02:55:00  OK     2204 files 4.1 GB
2024-11-03 02:55:01  END    total: 5904 files  9.78 GB  errors: 0

NOTE: Some paths contain legacy credentials marked for rotation Q1-2025.
      Do not distribute outside IR team.
EOF

# ── SECRET 1: VPN wachtwoord in DOCX ─────────────────────────────────────────
cat > /tmp/vpn_doc.md << 'EOF'
# VPN Toegang — Nordwind Logistics

**Document:** IT-ONB-044  
**Versie:** 3.2  
**Datum:** 15 maart 2024  
**Classificatie:** INTERN

## Inleiding

Dit document beschrijft de VPN-toegang voor directieleden en remote workers.

## Installatie GlobalProtect

1. Download de client van https://vpn.nordwind-logistics.nl
2. Importeer het bedrijfscertificaat (IT helpdesk)
3. Log in met uw AD-gegevens

## Directie-accounts

| Gebruiker | Rol | VPN profiel |
|-----------|-----|-------------|
| M. van den Berg | CEO | Executive-Global |
| L. Chen | CFO | Executive-Global |

### CEO VPN-gegevens (tijdelijk — rotatie gepland)

> **Let op:** dit blad wordt na activatie vernietigd.

- Gebruikersnaam: `m.vandenberg`
- **wachtwoord:** `VeloCity-VPN-9kLm2!`
- 2FA: YubiKey serial 8844221

## Support

IT Helpdesk: +31 10 123 4567 | helpdesk@nordwind-logistics.nl
EOF
mkdocx /tmp/vpn_doc.md "$DUMP/IT/onboarding/VPN_toegang_2024.docx"

# ── SECRET 2: DB password inside ZIP ─────────────────────────────────────────
mkdir -p /tmp/backup_inner
cat > /tmp/backup_inner/restore_notes.txt << 'EOF'
Nordwind Logistics — PostgreSQL restore procedure
=================================================
Backup host: nw-db-backup01.internal
Database: nordwind_production
Last verified restore: 2024-03-14

Connection for restore (break-glass account):
  host=nw-db-prod01.nordwind.internal port=5432 dbname=nordwind_production
  user=restore_breakglass
  password=PgProd_Nordwind_7xK!mQ

Rotate after any restore drill. Ticket IT-8842 tracks rotation.
EOF
cat > /tmp/backup_inner/MANIFEST.txt << 'EOF'
pg_dump custom format backup
Created: 2024-03-15 02:00 CET
Size: 4.2 GB (not included in this exercise dump)
Tables: 847
EOF
# fake binary blob so zip feels real
dd if=/dev/urandom of=/tmp/backup_inner/nordwind_prod_20240315.dump bs=1024 count=64 status=none 2>/dev/null || \
  python3 -c "open('/tmp/backup_inner/nordwind_prod_20240315.dump','wb').write(b'PGDMP' + os.urandom(65536))" 2>/dev/null || \
  head -c 65536 /dev/urandom > /tmp/backup_inner/nordwind_prod_20240315.dump 2>/dev/null || true

(cd /tmp/backup_inner && zip -q "$DUMP/IT/backups/nightly_2024-03-15.zip" ./*)
rm -rf /tmp/backup_inner

# ── SECRET 3: AWS key in JSON ────────────────────────────────────────────────
cat > "$DUMP/IT/cloud/aws_migration_draft.json" << 'EOF'
{
  "project": "nordwind-aws-migration",
  "status": "draft",
  "owner": "d.jansen@nordwind-logistics.nl",
  "regions": ["eu-west-1", "ap-east-1"],
  "notes": "DO NOT COMMIT — local draft only",
  "accounts": {
    "production": {
      "account_id": "884422115566",
      "access_key_id": "AKIA4NORDWIND9SECRET",
      "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
      "rotation_due": "2024-12-01"
    },
    "staging": {
      "account_id": "112233445566",
      "access_key_id": "AKIATESTNOTREAL00001",
      "secret_access_key": "not-a-real-secret-key-here"
    }
  },
  "s3_buckets": ["nw-logistics-docs", "nw-backups-eu"],
  "terraform_state": "s3://nw-tf-state/migration.tfstate"
}
EOF

# ── SECRET 4: GitHub PAT in log ───────────────────────────────────────────────
cat > "$DUMP/IT/deploy_logs/build_20240312.log" << 'EOF'
[2024-03-12 14:02:11] INFO  Starting pipeline nw-portal-deploy #8842
[2024-03-12 14:02:12] INFO  Checking out feature/shanghai-routes
[2024-03-12 14:02:15] INFO  Running npm ci
[2024-03-12 14:03:44] INFO  Running tests (142 passed, 0 failed)
[2024-03-12 14:04:01] WARN  GITHUB_TOKEN not in env, using fallback from legacy config
[2024-03-12 14:04:01] DEBUG export GITHUB_TOKEN=ghp_NwL0g1st1cs_BreachSim_a8f3c2
[2024-03-12 14:04:02] INFO  Cloning private dependency nw-shared-ui
[2024-03-12 14:05:33] INFO  Building Docker image nw-portal:20240312.8842
[2024-03-12 14:08:19] INFO  Pushing to registry.nordwind.internal
[2024-03-12 14:09:02] INFO  Deploy to staging OK
[2024-03-12 14:09:03] INFO  Pipeline finished SUCCESS
EOF

# ── SECRET 5a: BSN in JSON (+ decoy BSN) ─────────────────────────────────────
cat > "$DUMP/HR/employee_records_2024.json" << 'EOF'
{
  "export_date": "2024-10-01",
  "source": "AFAS HR",
  "employees": [
    {
      "id": "NW-00421",
      "name": "Jan de Vries",
      "department": "Operations",
      "burgerservicenummer": "123456782",
      "email": "j.devries@nordwind-logistics.nl",
      "start_date": "2019-03-15"
    },
    {
      "id": "NW-00887",
      "name": "Sophie Bakker",
      "department": "Finance",
      "burgerservicenummer": "987654329",
      "email": "s.bakker@nordwind-logistics.nl",
      "start_date": "2021-06-01"
    },
    {
      "id": "NW-00200",
      "name": "Test User Sandbox",
      "department": "IT",
      "burgerservicenummer": "999999999",
      "email": "test.user@nordwind-logistics.nl",
      "note": "SANDBOX — invalid BSN for testing"
    },
    {
      "id": "NW-01102",
      "name": "Anna Smit",
      "department": "Marketing",
      "burgerservicenummer": "246813579",
      "email": "a.smit@nordwind-logistics.nl"
    }
  ]
}
EOF

# ── SECRET 5b: BSN in PDF ────────────────────────────────────────────────────
cat > /tmp/bakker_privacy.md << 'EOF'
# Privacyverklaring Medewerker

**Nordwind Logistics BV**  
HR-FORM-012 Rev. 4

---

**Medewerker:** Sophie Bakker  
**Afdeling:** Finance  
**Datum ondertekening:** 12 januari 2024

Ik verklaar kennis te hebben genomen van het privacybeleid van Nordwind Logistics BV
en geef toestemming voor verwerking van mijn persoonsgegevens conform AVG.

**Persoonsgegevens registratie:**

| Veld | Waarde |
|------|--------|
| Naam | Sophie Bakker |
| BSN | 987654329 |
| Adres | Kralingseweg 884, 3062 CG Rotterdam |

Handtekening: _________________________

*Dit document is vertrouwelijk.*
EOF
mkpdf /tmp/bakker_privacy.md "$DUMP/HR/privacy_acknowledgement_Bakker.pdf"

# ── SECRET 5c: BSN in payroll ZIP ────────────────────────────────────────────
mkdir -p /tmp/payroll_inner
cat > /tmp/payroll_inner/employees.csv << 'EOF'
employee_id,name,department,bsn,gross_monthly_eur
NW-00421,Jan de Vries,Operations,123456782,4200.00
NW-00633,Pieter Jansen,Warehouse,111222333,3800.00
NW-00887,Sophie Bakker,Finance,987654329,5100.00
NW-01102,Anna Smit,Marketing,246813579,3900.00
NW-00200,Test User Sandbox,IT,999999999,0.00
EOF
cat > /tmp/payroll_inner/README.txt << 'EOF'
Payroll export Q3 2024 — CONFIDENTIAL
Exported from Exact Online by s.bakker@nordwind-logistics.nl
EOF
(cd /tmp/payroll_inner && zip -q "$DUMP/Finance/payroll/payroll_Q3_2024.zip" ./*)
rm -rf /tmp/payroll_inner

# ── SECRET 6: Chinese 密码 in JSON ───────────────────────────────────────────
cat > "$DUMP/China_Office/warehouse_system_config.json" << 'EOF'
{
  "system": "Nordwind WMS Shanghai",
  "site_code": "CN-SHA-01",
  "version": "2.4.1",
  "locale": "zh-CN",
  "admin_contact": "li.wei@nordwind-logistics.cn",
  "database": {
    "host": "10.88.42.10",
    "name": "nw_wms_sha",
    "user": "wms_service"
  },
  "integration": {
    "eu_hq_endpoint": "https://wms.nordwind-logistics.nl/api/v2",
    "api_key_label": "密码",
    "api_key_value": "Nordwind_Shanghai_密钥_8842",
    "sync_interval_minutes": 15
  },
  "labels": {
    "username": "用户名",
    "password": "密码",
    "note": "仓库系统密钥 — 仅限运维团队"
  }
}
EOF

# ── SECRET 7: Stripe key in DOCX ─────────────────────────────────────────────
cat > /tmp/stripe_contract.md << 'EOF'
# Vendor Agreement — Stripe Payment Processing

**Parties:** Nordwind Logistics BV and Stripe Payments Europe Ltd.  
**Effective date:** 1 February 2024  
**Reference:** FIN-CON-2024-0088

## 1. Services

Stripe shall provide payment processing for Nordwind's customer portal
and B2B invoice settlements in EUR and USD.

## 2. Technical integration

Integration uses Stripe Connect with the following credentials provisioned
by Stripe onboarding (live environment):

```
Publishable key: pk_live_NwPublish2024abc
Secret key: sk_live_NwStripe2024xK9mP2qR7
Webhook signing secret: whsec_nordwind2024placeholder
```

**Important:** Store secret key in vault only. This copy exists because
finance lead pasted it during kickoff — rotate if leaked.

## 3. Fees

Standard Stripe EU pricing applies. Volume discount tier 2 from €2M/month.

## 4. Term

36 months, auto-renewal.

Signed:

_________________________  Nordwind Logistics BV  
_________________________  Stripe Payments Europe Ltd.
EOF
mkdocx /tmp/stripe_contract.md "$DUMP/Finance/contracts/vendor_stripe_agreement.docx"

# ── SECRET 8: Final flag in PDF ──────────────────────────────────────────────
cat > /tmp/board_minutes.md << 'EOF'
# Board of Directors — Meeting Minutes

**Nordwind Logistics BV**  
**Date:** 18 December 2024  
**Location:** HQ Rotterdam + videoconference  
**Present:** M. van den Berg (CEO), L. Chen (CFO), board members  
**Secretary:** E. de Groot

## Agenda

1. Q4 financial results
2. Shanghai expansion update
3. Cybersecurity tabletop exercise
4. AOB

## 1. Q4 Financial Results

Revenue up 12% YoY. CFO presented detailed breakdown. Approved.

## 2. Shanghai Expansion

Warehouse phase 2 on schedule. CN-SHA-01 integration with EU WMS complete.

## 3. Cybersecurity Tabletop Exercise

External red team scheduled for November. IT to prepare scope document.
**Exercise completion code for vendor billing:**

> `FLAG{smb_ripgrep_trufflehog_master}`

Submit to procurement portal after debrief.

## 4. AOB

None.

*Minutes approved 20 December 2024.*
EOF
mkpdf /tmp/board_minutes.md "$DUMP/Legal/board/board_minutes_Q4_2024.pdf"

# ── Decoy files ──────────────────────────────────────────────────────────────
cat > "$DUMP/IT/legacy/passwords_OLD.txt" << 'EOF'
=== RETIRED PASSWORDS — DO NOT USE ===
Last updated: 2019-06-01
Migrated to LastPass Enterprise 2019-07

admin / changeme
root / toor
vpn-test / Welkom123
wachtwoord: Welkom123  (generic onboarding 2018)
wifi-guest / NordwindGuest2019
EOF

cat > "$DUMP/Shared/recipes/coffee.txt" << 'EOF'
Office Coffee Recipe (Shared drive classic)
===========================================
The secret ("geheim") to good coffee: fresh beans, 93°C water, 18g dose.
Not an actual company secret. Just caffeine.
EOF

cat > "$DUMP/IT/cloud/aws_migration_draft.json.bak" << 'EOF'
{"note": "backup of draft before redaction", "access_key_id": "AKIAREDACTED000000"}
EOF

# ── Generate lots of boring files with Python ────────────────────────────────
export DUMP
python3 << 'PYEOF'
import json, os, random, textwrap
from pathlib import Path

DUMP = Path(os.environ["DUMP"])

random.seed(42)

DEPARTMENTS = {
    "HR": ["onboarding", "policies", "exit_interviews"],
    "Finance/invoices/2023": [],
    "Finance/invoices/2024": [],
    "Marketing/campaigns/2024": [],
    "Operations/routes": [],
    "Operations/warehouse": [],
    "Shared/meeting_notes": [],
    "IT/tickets": [],
    "Legal/contracts": [],
    "Archives/2019": [],
    "Archives/2020": [],
    "Archives/2021": [],
    "China_Office/reports": [],
}

MEETING_TEMPLATES = [
    "Weekly standup — {dept}. Attendees: {n} people. Discussed deadlines.",
    "Budget review Q{q}. No action items. Coffee machine broken again.",
    "Vendor call with {vendor}. Pricing unchanged. Follow up in 2 weeks.",
    "Team outing planning. Location: {place}. RSVP by Friday.",
]

INVOICE_VENDORS = ["PostNL", "Shell Fleet", "Office Depot", "KPN Business", "Ahoy Catering"]
ROUTE_CITIES = ["Rotterdam", "Antwerp", "Hamburg", "Paris", "Milan", "Prague", "Warsaw"]

def write_boring_txt(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")

# HR policies
for i in range(1, 16):
    write_boring_txt(
        DUMP / "HR/policies" / f"policy_HR_{i:03d}.txt",
        f"Nordwind Logistics — HR Policy {i:03d}\n"
        f"Effective: 202{i%4}-01-01\n"
        f"{textwrap.fill('Standard workplace policy document. Refer to HR portal for full text. ' * 3)}"
    )

# Meeting notes
for i in range(1, 45):
    t = random.choice(MEETING_TEMPLATES).format(
        dept=random.choice(["Ops", "Finance", "IT", "Marketing"]),
        n=random.randint(3, 12),
        q=random.randint(1, 4),
        vendor=random.choice(INVOICE_VENDORS),
        place=random.choice(["De Kuip", "Euromast", "SS Rotterdam"]),
    )
    write_boring_txt(DUMP / "Shared/meeting_notes" / f"notes_2024_{i:03d}.txt", t)

# Invoices
for year in [2023, 2024]:
    for i in range(1, 35):
        vendor = random.choice(INVOICE_VENDORS)
        amt = round(random.uniform(120, 8900), 2)
        write_boring_txt(
            DUMP / f"Finance/invoices/{year}" / f"INV-{year}-{i:04d}.txt",
            f"INVOICE\nVendor: {vendor}\nAmount: EUR {amt:.2f}\nStatus: PAID\nRef: NW-{year}-{random.randint(1000,9999)}"
        )

# IT tickets
for i in range(1, 60):
    write_boring_txt(
        DUMP / "IT/tickets" / f"ticket_{8840+i}.txt",
        f"IT Ticket #{8840+i}\nStatus: Closed\nSubject: {random.choice(['Password reset', 'Monitor flicker', 'VPN slow', 'Printer jam', 'Outlook sync'])}\n"
        f"Resolution: Standard fix applied.\nNote: user asked to reset password to password123 — denied per policy."
    )

# Operations routes JSON
for i in range(1, 25):
    route = {
        "route_id": f"RT-EU-{i:04d}",
        "origin": "Rotterdam",
        "destinations": random.sample(ROUTE_CITIES, k=3),
        "distance_km": random.randint(200, 1800),
        "active": True,
    }
    p = DUMP / "Operations/routes" / f"route_{i:04d}.json"
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(route, indent=2))

# Marketing drafts with fake passwords
for i in range(1, 20):
    write_boring_txt(
        DUMP / "Marketing/campaigns/2024" / f"draft_campaign_{i}.txt",
        f"Campaign draft {i}\nTagline ideas...\n"
        f"Placeholder login for ad platform: test@test.com / test1234\n"
        f"(not real credentials)\n"
    )

# Archives
for year in [2019, 2020, 2021]:
    for i in range(1, 30):
        write_boring_txt(
            DUMP / f"Archives/{year}" / f"doc_{year}_{i:04d}.txt",
            f"Archived document {year}/{i:04d}\nNordwind Logistics historical record.\n"
            f"Content migrated from legacy DMS.\n" + "Lorem ipsum. " * 20
        )

# China office reports
for i in range(1, 12):
    write_boring_txt(
        DUMP / "China_Office/reports" / f"monthly_report_2024_{i:02d}.txt",
        f"Shanghai Office Monthly Report 2024-{i:02d}\n"
        f"Throughput: {random.randint(800, 2400)} TEU\n"
        f"Staff count: {random.randint(45, 80)}\n"
        f"Notes: Normal operations.\n"
    )

# Legal boilerplate
for i in range(1, 10):
    write_boring_txt(
        DUMP / "Legal/contracts" / f"NDA_counterparty_{i:04d}.txt",
        f"MUTUAL NDA — Counterparty {i:04d}\nStandard Nordwind template v2.\nSigned 2023.\n"
    )

# Warehouse shift logs
for i in range(1, 18):
    write_boring_txt(
        DUMP / "Operations/warehouse" / f"shift_log_{i:04d}.txt",
        f"Shift log #{i:04d}\nPallets processed: {random.randint(100, 500)}\nIncidents: 0\n"
    )

# HR onboarding docs (boring)
for name in ["Welcome_Pack", "Expense_Policy", "Travel_Guidelines", "Code_of_Conduct"]:
    write_boring_txt(
        DUMP / "HR/onboarding" / f"{name}.txt",
        f"Nordwind Logistics — {name.replace('_', ' ')}\nStandard employee document.\n"
    )

# Shared templates
for i in range(1, 8):
    write_boring_txt(
        DUMP / "Shared/templates" / f"letterhead_template_{i}.txt",
        f"[Nordwind Logistics letterhead template v{i}]\n"
    )

print(f"Generated decoy files under {DUMP}")
PYEOF

# ── a few more pandoc docs (boring) ──────────────────────────────────────────
cat > /tmp/hr_handbook_snippet.md << 'EOF'
# Employee Handbook — Excerpt

Welcome to Nordwind Logistics BV.

## Working hours

Standard hours: 08:30–17:00 CET.

## Leave policy

Refer to HR portal. Contact HR@nordwind-logistics.nl.

## IT Acceptable Use

Do not share credentials. Report incidents to security@nordwind-logistics.nl.
EOF
mkpdf /tmp/hr_handbook_snippet.md "$DUMP/HR/onboarding/Employee_Handbook_2024.pdf"

cat > /tmp/marketing_brief.md << 'EOF'
# Marketing Brief — Spring Campaign 2024

Target: B2B logistics decision makers in Benelux.

Channels: LinkedIn, trade shows, email nurture.

Budget: EUR 120,000.

KPIs: MQLs, brand awareness.
EOF
mkdocx /tmp/marketing_brief.md "$DUMP/Marketing/campaigns/2024/Spring_Campaign_Brief.docx"

# nested zip inside archives
mkdir -p /tmp/archive_zip
echo "Old project files — nothing sensitive" > /tmp/archive_zip/readme.txt
echo "password=notused" > /tmp/archive_zip/config.ini
(cd /tmp/archive_zip && zip -q "$DUMP/Archives/2020/project_legacy_2020.zip" ./*)
rm -rf /tmp/archive_zip

# ── Advanced formats: scanned PDF, PNG, XLSX, EML, EXIF JPG, zip>7z ─────────
echo "==> Generating advanced artifacts (Python)..."
export DUMP
python3 "$ROOT/generate_advanced.py"

# ── Company flavor: cruft, lore, PDFs, xlsx, email threads, duplicates ────────
echo "==> Generating company flavor (Python)..."
python3 "$ROOT/generate_flavor.py"

# file count
COUNT=$(find "$DUMP" -type f | wc -l)
echo "==> Done. $COUNT files in smb_dump/"
echo "    Verify: rga -i 'FLAG\{smb_ripgrep' smb_dump/"
