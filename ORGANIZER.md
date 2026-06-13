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
| 15 | Redis password | `IT/legacy/redis.conf` | `RedisNw-Cache-8842!` | `rga` on `.conf` |
| 16 | Spring DB password | `IT/cloud/application.yml` | `SpringStg_NwPortal_7xK!` | `rga` on `.yml` |
| 17 | SendGrid API key | `IT/cloud/application.yml` | `SG.NwMail2024.xK9secret` | `rga` on `.yml` |
| 18 | Terraform DB password | `IT/cloud/terraform.tfvars` | `TfNwDb_Staging_7xK!` | `rga` on `.tfvars` |
| 19 | GlobalProtect PSK | `IT/onboarding/executive_globalprotect.ovpn` | `GP-Exec-PSK-2024-Rot` | `rga` on `.ovpn` |
| 20 | npm registry token | `IT/deploy_logs/.npmrc` | `npm_NwRegistry_8842token` | `rg --hidden` (dotfile) |
| 21 | **Bonus flag (kube)** | `IT/cloud/.kube/config` | `BONUS{kube_config_hunter}` | `rga --hidden` on kubeconfig |
| 22 | MongoDB root password | `Operations/warehouse/docker-compose.yml` | `MongoNw-Docker-8842` | `rga` on compose |
| 23 | Vault unseal key | `IT/legacy/vault.hcl` | `VaultNw-Unseal-8842-xK9m` | `rga` on `.hcl` |
| 24 | **Bonus flag (KeePass)** | `Finance/nordwind_passwords.kdbx` | `BONUS{keepass_windmill_vault}` | Brute force master → open vault |
| 25 | Datadog API key | same `.kdbx` entry | `dd_api_NwMonitor_8842secret` | After KeePass unlock |
| 26 | Customs broker API | same `.kdbx` entry | `CustomsNw-API-8842` | After KeePass unlock |
| 27 | PKCS12 password | same `.kdbx` → unlocks `Operations/customs/broker_client_auth.p12` | `P12Nw-8842!` | KeePass → `openssl pkcs12` |
| 28 | JKS store password | same `.kdbx` → unlocks `IT/cloud/nw-portal.jks` | `JksNw-8842!` | KeePass → `keytool -list` |

### KeePass brute force

| Item | Value |
|------|-------|
| File | `Finance/nordwind_passwords.kdbx` |
| Master password | `Nordwind2024` |
| Hint | `IT/tickets/ticket_7734_keepass_policy.txt` (CompanyName + year) |
| Wordlist | `IT/backups/password_audit_wordlist.txt` (contains the password) |

```bash
# john (install keepass2john from john-jumbo)
keepass2john smb_dump/Finance/nordwind_passwords.kdbx > /tmp/kp.hash
john --wordlist=smb_dump/IT/backups/password_audit_wordlist.txt /tmp/kp.hash

# hashcat
hashcat -m 13400 -a 0 kp.hash smb_dump/IT/backups/password_audit_wordlist.txt

# keepassxc-cli (interactive)
keepassxc-cli open smb_dump/Finance/nordwind_passwords.kdbx

# pykeepass
python3 -c "from pykeepass import PyKeePass; kp=PyKeePass('smb_dump/Finance/nordwind_passwords.kdbx', password='Nordwind2024'); print(kp.entries)"
```

### .env files (plaintext in dump)

| File | Notable content |
|------|-----------------|
| `IT/deploy/.env` | Redis password, pointers to `.kdbx` / `.p12` / `.jks` |
| `IT/deploy/.env.production` | SendGrid key (duplicate of yaml), `see_keepass_vault` placeholders |
| `IT/cloud/.env.local` | Dev-only decoys |
| `Finance/.env` | Points to `nordwind_passwords.kdbx` |
| `IT/deploy_logs/.env.staging` | From filetypes pass |

### Office formats (LibreOffice — rga-unfriendly)

| # | Item | Location | Value | Discovery |
|---|------|----------|-------|-----------|
| 29 | SAP vendor API key | `Finance/invoices/2024/SAP_vendor_integration_memo.doc` | `sap_api_NwVendor_8842secret` | `libreoffice --convert-to txt` or strings |
| 30 | Legacy HR wachtwoord | `HR/policies/IT_account_reset_procedure_2019.doc` | `LegacyHr-Wachtwoord-8842!` | LibreOffice / strings on `.doc` |
| 31 | Emergency access token | `Finance/payroll/emergency_access_roster_Q4.xlsx` | `BgNw-Emergency-2024-xK9` | `unzip -p … xl/sharedStrings.xml \| rg` |
| 32 | Shell Fleet API key | `Operations/routes/fuel_card_registry_2024.xlsx` → hidden `shell_api` | `fleet_api_NwShell_8842secret` | `unzip -p … xl/worksheets/*.xml \| rg` |
| 33 | Archive export key | `Finance/invoices/2023/archive_invoice_index_2023.xls` | `ArchNw-Xls-8842legacy` | LibreOffice convert `.xls` → txt/csv |

Decoy: `HR/policies/office_etiquette_2017.doc` (no secrets).

Regenerating requires **LibreOffice** (`libreoffice --headless`) in addition to other deps.

## Config filetype decoys (no scoring value)

Generated by `generate_filetypes.py`: `tnsnames.ora`, `sqlnet.ora`, `elasticsearch.yml`, `server.xml`, `web.config`, `application.properties`, `bootstrap.yaml`, `consul.hcl`, `pip.conf`, `.pypirc`, `NuGet.Config`, `settings.xml`, `.netrc`, `.pgpass`, `mongod.conf`, `my.cnf`, `gitlab-ci.yml`, `azure-pipelines.yml`, `nw-portal.toml`, `openvpn.conf`, benign `terraform.tfstate`, `.env.staging` (JWT placeholder).

## Real crypto material (`generate_keys.py`)

Generated with `ssh-keygen` and `openssl` — valid key/cert structure; **CTF-only, not used anywhere live**.

| Path | Type |
|------|------|
| `IT/deploy/ci_deploy_ed25519` (+ `.pub`) | ed25519 CI deploy key |
| `IT/deploy/id_rsa` (+ `.pub`) | RSA legacy deploy key |
| `IT/deploy/.ssh/config`, `authorized_keys` | SSH client config cruft |
| `China_Office/.ssh/id_ed25519` (+ `.pub`) | Shanghai ops key copy |
| `IT/onboarding/nw-deploy.key`, `nw-deploy.pem` | TLS key + self-signed cert |
| `IT/onboarding/vpn-ca.key`, `vpn-ca.crt` | VPN CA (also embedded in `.ovpn`) |
| `Operations/warehouse/tls.key`, `server.crt` | Warehouse tools TLS |
| `Archives/2019/legacy_intranet.key`, `.crt` | Legacy intranet TLS |
| `IT/cloud/.kube/config` | Real `certificate-authority-data` from VPN CA |

TruffleHog will flag the private keys — intentional. No passphrase on SSH keys.

## Generator dependencies

Regenerating the dump requires: `pandoc`, `zip`, `7z`, `exiftool`, `ssh-keygen`, `openssl`, `keytool` (JDK), `libreoffice`, Python 3 with packages from `requirements-generate.txt` (`pip install -r requirements-generate.txt`).

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
