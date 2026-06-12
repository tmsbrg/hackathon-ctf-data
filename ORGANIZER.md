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
| 8 | **Final flag** | `Legal/board_minutes_Q4_2024.pdf` | `FLAG{smb_ripgrep_trufflehog_master}` |

## Decoys (intentional noise)

- `HR/employee_records_2024.json` — fake BSN `999999999` (fails 11-proef)
- `IT/legacy/passwords_OLD.txt` — `admin/changeme`, `wachtwoord: Welkom123` (retired)
- `Shared/recipes/coffee.txt` — contains word "geheim" in recipe context
- Multiple `password123`, `test1234` across Marketing drafts

## Verification commands

```bash
rga -i 'VeloCity-VPN' smb_dump/
rga 'AKIA4NORDWIND' smb_dump/
rga 'ghp_NwL0g1st1cs' smb_dump/
rga 'FLAG\{smb_ripgrep' smb_dump/
trufflehog filesystem smb_dump/ --no-update
```

## BSN 11-proef check

All three valid BSNs pass the Dutch elfproef (weighted sum mod 11).
