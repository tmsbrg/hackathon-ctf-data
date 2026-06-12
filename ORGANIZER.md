# Organizer Solutions — Operation Windmill

**Do not share with participants.**

## Regenerating the dump

```bash
./generate_ctf.sh
```

## All secrets

| # | Item | Location | Value |
|---|------|----------|-------|
| 1 | CEO VPN (wachtwoord) | `IT/onboarding/VPN_toegang_2024.docx` | `VeloCity-VPN-9kLm2!` |
| 2 | DB password | `IT/backups/nightly_2024-03-15.zip` → `restore_notes.txt` | `PgProd_Nordwind_7xK!mQ` |
| 3 | AWS key | `IT/cloud/aws_migration_draft.json` | `AKIA4NORDWIND9SECRET` |
| 4 | GitHub PAT | `IT/deploy_logs/build_20240312.log` | `ghp_NwL0g1st1cs_BreachSim_a8f3c2` |
| 5a | BSN Jan de Vries | `HR/employee_records_2024.json` | `123456782` |
| 5b | BSN Sophie Bakker | `HR/privacy_acknowledgement_Bakker.pdf` | `987654329` |
| 5c | BSN Pieter Jansen | `Finance/payroll_Q3_2024.zip` → `employees.csv` | `111222333` |
| 6 | Shanghai 密码 | `China_Office/warehouse_system_config.json` | `Nordwind_Shanghai_密钥_8842` |
| 7 | Stripe key | `Finance/contracts/vendor_stripe_agreement.docx` | `sk_live_NwStripe2024xK9mP2qR7` |
| 8 | **Final flag** | `Legal/board/board_minutes_Q4_2024.pdf` | `FLAG{smb_ripgrep_trufflehog_master}` |

## Extended / bonus secrets

| # | Item | Location | Value | Discovery |
|---|------|----------|-------|-----------|
| 9 | Contractor BSN | `HR/exit_interviews/Mulder_contract_scan.pdf` | `147258364` | OCR / visual (image-only PDF) |
| 10 | WMS terminal 密码 | `China_Office/training/wms_terminal_screenshot.png` | `ShaWMS-2024-Rot` | OCR / open image |
| 11 | Finance API key | `Finance/payroll/salary_bands_2024.xlsx` → hidden sheet `geheim` | `fin_api_NwQ3_8842secret` | `unzip -p … \| rg` |
| 12 | Portal reset (Dutch) | `IT/tickets/helpdesk_reset_vandenberg.eml` | `PortalReset-2024-xK9` | `rga` on `.eml` |
| 13 | Bonus flag (EXIF) | `Shared/office_party_2024.jpg` | `BONUS{exif_metadata_dig}` | `exiftool` |
| 14 | Legacy Oracle pwd | `IT/backups/legacy_oracle_2019.zip` → `configs.7z` | `OrclNw2019!sys` | `unzip` + `7z x` |

## Generator dependencies

Regenerating the dump requires: `pandoc`, `zip`, `7z`, `exiftool`, Python 3 with `openpyxl`, `Pillow`, `reportlab`.

OCR is **not** required at generation time — scanned PDF/PNG are image-only by design.

## Decoys (intentional noise)

- `HR/employee_records_2024.json` — fake BSN `999999999` (fails 11-proef)
- `IT/legacy/passwords_OLD.txt` — `admin/changeme`, `wachtwoord: Welkom123` (retired)
- `Shared/recipes/coffee.txt` — contains word "geheim" in recipe context
- Multiple `password123`, `test1234` across Marketing drafts
- SMB cruft: `desktop.ini`, `Thumbs.db`, `.DS_Store`, `~$VPN_toegang_2024.docx` (Word lock — may cause rga/pandoc errors)
- Duplicate filenames: `INV-2024-0007 (1).txt`, `route_0004_backup.json`, etc.
- 20 lore files cross-referencing named employees (no secrets)
- 3 benign `.xlsx`, 5 policy PDFs, 3-message office-move `.eml` thread

## Verification commands

```bash
rga -i 'VeloCity-VPN' smb_dump/
rga 'AKIA4NORDWIND' smb_dump/
rga 'ghp_NwL0g1st1cs' smb_dump/
rga 'FLAG\{smb_ripgrep' smb_dump/
trufflehog filesystem smb_dump/ --no-update
exiftool -UserComment smb_dump/Shared/office_party_2024.jpg
unzip -p smb_dump/Finance/payroll/salary_bands_2024.xlsx 'xl/worksheets/sheet2.xml' | rg fin_api
7z x -so <(unzip -p smb_dump/IT/backups/legacy_oracle_2019.zip configs.7z) | rg OrclNw
```

## BSN 11-proef check

All three core BSNs plus contractor BSN `147258364` pass the Dutch elfproef.
