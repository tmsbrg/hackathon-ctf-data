# Operation Windmill — SMB Share Breach CTF

**Scenario:** Your red team simulated an intrusion at **Nordwind Logistics BV** (Rotterdam HQ, Shanghai subsidiary). Before the defenders pulled the plug, you mirrored several SMB shares into `smb_dump/`. The dump is messy — years of spreadsheets, HR PDFs, IT backups, and office documents from three continents.

Your job is not to read every file by hand. Use **ripgrep-all** (`rga`) and **TruffleHog** (or similar secret scanners) to hunt through plain text *and* binary formats (PDF, DOCX, ZIP, JSON, …).

## Setup

```bash
# ripgrep-all — searches inside PDFs, docx, zip, etc.
# https://github.com/phiresky/ripgrep-all
rga --version

# If rga complains about cache permissions, use a writable cache path:
# rga --rga-cache-path=/tmp/rga-cache ...

# TruffleHog — entropy & pattern-based secret detection
# https://github.com/trufflesecurity/trufflehog
trufflehog filesystem ./smb_dump
```

## Your mission

Find **all eight classified items** below. Each is real — buried in noise, other languages, and decoys.

| # | Target | Hint |
|---|--------|------|
| 1 | CEO VPN credential (Dutch label) | IT share, onboarding doc |
| 2 | Production database password | Old backup bundle on IT share |
| 3 | AWS access key (live-looking) | Cloud migration notes |
| 4 | GitHub personal access token | CI/CD log from March 2024 |
| 5 | Employee BSN (×3 unique, valid 11-proef) | HR & payroll paths |
| 6 | Shanghai warehouse secret (Chinese label) | China office config |
| 7 | Stripe live API key | Finance contract archive |
| 8 | **Final flag** | Board meeting minutes (Q4 2024) |

Submit the **final flag** to score. Finding all eight proves you searched like a pro.

## Extended challenges (bonus)

These need **extra tooling** beyond plain `rga`. Not required for the main flag, but worth points if you run a leaderboard.

| # | Target | Hint | Tools |
|---|--------|------|-------|
| 9 | Contractor BSN (valid 11-proef) | HR exit interview scan | `tesseract`, `ocrmypdf`, or read the image PDF |
| 10 | WMS terminal password (Chinese) | Shanghai training folder screenshot | `tesseract`, or open the PNG |
| 11 | Finance API key | Payroll spreadsheet — hidden tab | `unzip -p file.xlsx 'xl/**/*.xml' \| rg …` |
| 12 | Executive portal reset (Dutch) | Helpdesk email export | `rga` / `rg` on `.eml` |
| 13 | **Bonus flag** | Summer party photo metadata | `exiftool` |
| 14 | Legacy Oracle password | IT backup — archive inside archive | `unzip` then `7z x` (rga won't read 7z) |
| 15 | Redis cache password | Legacy IT config | `rga` on `.conf` |
| 16 | Spring staging DB password | Cloud `application.yml` | `rga` on `.yml` |
| 17 | SendGrid API key | Same Spring config | `rga` on `.yml` |
| 18 | Terraform staging DB password | `terraform.tfvars` | `rga` on `.tfvars` |
| 19 | GlobalProtect PSK | Executive VPN export | `rga` on `.ovpn` |
| 20 | Private npm registry token | Deploy logs `.npmrc` | `rga --hidden` or `rg --hidden` (dotfile) |
| 21 | **Bonus flag (kube)** | Kubernetes kubeconfig | `rga --hidden` on `.kube/config` |
| 22 | MongoDB dev password | Warehouse `docker-compose.yml` | `rga` on compose |
| 23 | Vault unseal key | Legacy `vault.hcl` | `rga` on `.hcl` |

The dump also includes **decoy config cruft** in formats from real breach hunts: `.properties`, `.toml`, `.ora`, `server.xml`, `web.config`, `NuGet.Config`, `.netrc`, `.pgpass`, CI YAML, and more.

**Real-looking crypto material** (generated with `ssh-keygen` / `openssl` for realism): deploy keys in `IT/deploy/`, Shanghai `id_ed25519`, TLS `.key` / `.crt` pairs, VPN CA inside `executive_globalprotect.ovpn`. TruffleHog will scream — these are CTF props, not production keys.

## Toolchain checklist

```bash
rga / rg          # text, PDF text layer, docx, zip (not 7z or xlsx directly)
trufflehog        # high-entropy secrets
tesseract         # OCR for scanned PDFs and PNG screenshots
exiftool          # image metadata (EXIF)
7z                # extract .7z inside zip archives
unzip             # peek inside .xlsx (Office Open XML is a zip)
```

Optional install:

```bash
# Debian/Ubuntu
sudo apt install ripgrep-all trufflehog tesseract-ocr exiftool p7zip-full
pip install openpyxl pillow reportlab   # only needed to regenerate the dump
```

## Useful commands

```bash
# Search everything including binaries
rga -i 'wachtwoord|密码|bsn|burgerservicenummer' smb_dump/

# Dutch & Chinese password keywords
rga -i 'wachtwoord|geheim|密码|密钥' smb_dump/

# BSN pattern (9 digits, may include spaces/dots)
rga '\b[0-9]{3}[.\s]?[0-9]{3}[.\s]?[0-9]{3}\b' smb_dump/

# Let TruffleHog rip
trufflehog filesystem --no-update smb_dump/ 2>/dev/null

# Rip into zips
rga -i 'password|postgres|mysql' smb_dump/IT/backups/

# XLSX hidden sheets (Office files are zip XML)
unzip -p smb_dump/Finance/payroll/salary_bands_2024.xlsx 'xl/worksheets/*.xml' | rg -i 'fin_api|geheim'

# EXIF metadata pass
exiftool -a -u smb_dump/Shared/office_party_2024.jpg

# OCR a scanned PDF (no text layer)
tesseract smb_dump/HR/exit_interviews/Mulder_contract_scan.pdf stdout 2>/dev/null | rg BSN

# Nested 7z inside zip
unzip -l smb_dump/IT/backups/legacy_oracle_2019.zip
unzip -p smb_dump/IT/backups/legacy_oracle_2019.zip configs.7z > /tmp/configs.7z && 7z x -so /tmp/configs.7z | rg -i oracle

# Config-style extensions (yaml, tfvars, ovpn, npmrc, hcl, …)
rga -i 'password|token|apikey|requirepass' smb_dump/IT/
rga --hidden 'BONUS\{kube' smb_dump/   # dotfiles need --hidden
rg --hidden 'npm_NwRegistry' smb_dump/IT/deploy_logs/
find smb_dump -name '*.ovpn' -o -name '*.tfvars' -o -name '.npmrc' -o -name 'vault.hcl'

# Validate a deploy key looks real (optional)
ssh-keygen -l -f smb_dump/IT/deploy/ci_deploy_ed25519
openssl x509 -in smb_dump/IT/onboarding/nw-deploy.pem -noout -subject
```

## Rules

- No modifying files in `smb_dump/` (integrity hash in manifest).
- Automated tooling encouraged; manual grepping of 400+ files is masochism.
- Decoys are intentional. Not every `password123` is the answer.

## Share layout (partial)

```
smb_dump/
├── _manifest/          # download metadata
├── HR/
├── Finance/
├── IT/
├── Legal/
├── Marketing/
├── Operations/
├── Shared/
├── China_Office/
└── Archives/
```

Good hunting. *De gegevens wachten ergens tussen de facturen.*
