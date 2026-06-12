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
