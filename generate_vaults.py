#!/usr/bin/env python3
"""Generate PKCS#12, JKS, .env files, and KeePass (.kdbx) vaults.

KeePass master password is weak enough for basic brute force (wordlist in dump).
"""
from __future__ import annotations

import os
import shutil
import subprocess
import textwrap
from pathlib import Path

DUMP = Path(os.environ["DUMP"])

# KeePass — brute-forceable with IT/backups/password_audit_wordlist.txt
KEEPASS_MASTER = "Nordwind2024"

# Unlocked from KeePass entries (also unlock p12 / jks)
P12_PASSWORD = "P12Nw-8842!"
JKS_STORE_PASSWORD = "JksNw-8842!"

# Secrets inside KeePass (after crack)
KEEPASS_DATADOG_KEY = "dd_api_NwMonitor_8842secret"
KEEPASS_CUSTOMS_API = "CustomsNw-API-8842"
KEEPASS_BONUS_FLAG = "BONUS{keepass_windmill_vault}"


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(textwrap.dedent(content).strip() + "\n", encoding="utf-8")


def find_keytool() -> str:
    keytool = os.environ.get("KEYTOOL") or shutil.which("keytool")
    if not keytool:
        raise RuntimeError(
            "keytool not found — install a JDK or set KEYTOOL=/path/to/keytool"
        )
    return keytool


def openssl_pkcs12(
    key_path: Path,
    cert_path: Path,
    out_path: Path,
    password: str,
    friendly_name: str,
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.unlink(missing_ok=True)
    subprocess.run(
        [
            "openssl",
            "pkcs12",
            "-export",
            "-out",
            str(out_path),
            "-inkey",
            str(key_path),
            "-in",
            str(cert_path),
            "-name",
            friendly_name,
            "-passout",
            f"pass:{password}",
        ],
        check=True,
        capture_output=True,
    )


def openssl_self_signed(key_path: Path, cert_path: Path, subject: str) -> None:
    key_path.parent.mkdir(parents=True, exist_ok=True)
    key_path.unlink(missing_ok=True)
    cert_path.unlink(missing_ok=True)
    subprocess.run(
        [
            "openssl",
            "req",
            "-x509",
            "-newkey",
            "rsa:2048",
            "-keyout",
            str(key_path),
            "-out",
            str(cert_path),
            "-days",
            "825",
            "-nodes",
            "-subj",
            subject,
        ],
        check=True,
        capture_output=True,
    )


def generate_jks(jks_path: Path, store_password: str, alias: str) -> None:
    keytool = find_keytool()
    jks_path.parent.mkdir(parents=True, exist_ok=True)
    jks_path.unlink(missing_ok=True)
    subprocess.run(
        [
            keytool,
            "-genkeypair",
            "-alias",
            alias,
            "-keyalg",
            "RSA",
            "-keysize",
            "2048",
            "-keystore",
            str(jks_path),
            "-storepass",
            store_password,
            "-keypass",
            store_password,
            "-dname",
            "CN=nw-portal.nordwind.internal, OU=IT, O=Nordwind Logistics BV, C=NL",
            "-validity",
            "825",
        ],
        check=True,
        capture_output=True,
    )


def generate_keepass(kdbx_path: Path) -> None:
    try:
        from pykeepass import create_database
    except ImportError:
        raise RuntimeError(
            "pykeepass required for KeePass generation — pip install pykeepass "
            "or pip install -r requirements-generate.txt"
        ) from None

    kdbx_path.parent.mkdir(parents=True, exist_ok=True)
    kdbx_path.unlink(missing_ok=True)

    kp = create_database(str(kdbx_path), password=KEEPASS_MASTER, keyfile=None)

    finance = kp.add_group(kp.root_group, "Finance")
    it_group = kp.add_group(kp.root_group, "IT")
    ops = kp.add_group(kp.root_group, "Operations")

    kp.add_entry(
        finance,
        "Stripe backup (finance lead)",
        "stripe_live",
        "sk_live_NwStripe_BACKUP_from_vault",
        "Rotated in portal — old key for audit only",
    )
    kp.add_entry(
        it_group,
        "Datadog monitoring EU",
        "api_key",
        KEEPASS_DATADOG_KEY,
        "nw-monitor-prod — rotate quarterly",
    )
    kp.add_entry(
        it_group,
        "PKCS12 customs broker cert",
        "broker_cert.p12",
        P12_PASSWORD,
        "Operations/customs/broker_client_auth.p12",
    )
    kp.add_entry(
        it_group,
        "Portal Java keystore",
        "nw-portal.jks",
        JKS_STORE_PASSWORD,
        "IT/cloud/nw-portal.jks — storepass = keypass",
    )
    kp.add_entry(
        ops,
        "EU customs broker API",
        "api_key",
        KEEPASS_CUSTOMS_API,
        "Douane broker integration — CN broker endpoint",
    )
    kp.add_entry(
        kp.root_group,
        "CTF bonus",
        "flag",
        KEEPASS_BONUS_FLAG,
        "Tabletop exercise Easter egg",
    )

    kp.save()


AUDIT_WORDLIST = [
    "Nordwind",
    "nordwind",
    "NORDWIND",
    "Nordwind2024",
    "Nordwind2023",
    "Nordwind2025",
    "logistics",
    "Logistics",
    "Rotterdam",
    "windmill",
    "Windmill",
    "Windmill2024",
    "Welkom123",
    "VeloCity",
    "VeloCity2024",
    "nordwind2024",
    "Nordwind8842",
    "password123",
    "Welkom1234",
    "Euromast",
    "logistics2024",
]


def write_audit_wordlist(wordlist_path: Path) -> None:
    """Small audit wordlist — enough to crack KeePass via john/hashcat."""
    header = textwrap.dedent(
        """\
        # Nordwind IT — password audit sample wordlist (internal)
        # Used for weak-password checks on exported vaults / legacy accounts.
        # NOT the full corporate wordlist — subset for quarterly audit tooling.
        """
    ).strip()
    body = "\n".join(AUDIT_WORDLIST)
    wordlist_path.write_text(header + "\n" + body + "\n", encoding="utf-8")


def generate_env_files() -> None:
    write_text(
        DUMP / "IT/deploy/.env",
        f"""\
        # nw-build01 deploy agent — mirrored during incident response
        NODE_ENV=production
        PORT=3000
        DATABASE_URL=postgresql://portal_prod:REDACTED_USE_VAULT@nw-db-prod01:5432/nordwind_production
        REDIS_URL=redis://nw-cache01.internal:6379
        REDIS_PASSWORD=RedisNw-Cache-8842!
        JWT_SECRET=jwt_NwProd_NotInThisFile_SeeKeepass

        # Master secrets vault (finance lead maintains):
        KEEPASS_DB_PATH=../../Finance/nordwind_passwords.kdbx
        # Master password NOT stored here — see IT ticket #7734 / audit wordlist

        KEYSTORE_PATH=../cloud/nw-portal.jks
        PKCS12_CUSTOMS_PATH=../../Operations/customs/broker_client_auth.p12
        """,
    )

    write_text(
        DUMP / "IT/deploy/.env.production",
        """\
        # Production portal — partial export (secrets redacted in mirror)
        NODE_ENV=production
        APP_URL=https://portal.nordwind-logistics.nl
        SESSION_COOKIE_SECURE=true

        SENDGRID_API_KEY=SG.NwMail2024.xK9secret
        AWS_REGION=eu-west-1
        S3_BUCKET=nw-logistics-docs

        # Pulled from Finance/nordwind_passwords.kdbx after unlock:
        #   Datadog monitoring EU -> api_key
        #   Portal Java keystore -> nw-portal.jks passphrase
        DATADOG_API_KEY=see_keepass_vault
        KEYSTORE_PASSWORD=see_keepass_vault
        """,
    )

    write_text(
        DUMP / "IT/cloud/.env.local",
        """\
        # Daan Jansen local dev — accidentally mirrored from laptop
        NODE_ENV=development
        DATABASE_URL=postgresql://portal_dev:devonly@localhost:5432/nordwind_dev
        STRIPE_SECRET_KEY=sk_test_local_dev_not_real
        DEBUG=true
        LOG_LEVEL=debug
        """,
    )

    write_text(
        DUMP / "Finance/.env",
        """\
        # Exact Online export helper — finance workstation
        EXACT_CLIENT_ID=nordwind_exact_client
        EXACT_CLIENT_SECRET=exact_secret_placeholder_not_scored
        EXACT_DIVISION=884422

        # Password vault location (KeePass):
        NW_PASSWORD_VAULT=nordwind_passwords.kdbx
        # Sophie Bakker maintains — master password policy: IT-7734
        """,
    )


def generate_hints() -> None:
    write_text(
        DUMP / "IT/tickets/ticket_7734_keepass_policy.txt",
        """\
        IT Ticket #7734 — Closed
        Subject: KeePass master password policy exception request
        Requester: M. van den Berg (CEO)
        Owner: d.jansen@nordwind-logistics.nl

        CEO requested personal vault password match laptop login pattern:
        CompanyName + current calendar year (e.g. Nordwind + 2024).
        Approved for nordwind_passwords.kdbx on Finance share only.

        Security note: run password audit against password_audit_wordlist.txt
        before next tabletop — weak patterns flagged Q4 2024.

        Resolution: exception documented. Remind finance to use KeePass auto-type.
        """,
    )

    write_audit_wordlist(DUMP / "IT/backups/password_audit_wordlist.txt")


def main() -> None:
    DUMP.mkdir(parents=True, exist_ok=True)

    tmp = DUMP / ".tmp_vault_build"
    if tmp.exists():
        shutil.rmtree(tmp)
    tmp.mkdir()

    customs_key = tmp / "broker.key"
    customs_cert = tmp / "broker.crt"
    openssl_self_signed(
        customs_key,
        customs_cert,
        "/CN=broker-client.nordwind-logistics.nl/O=Nordwind Logistics BV/C=NL",
    )
    p12_out = DUMP / "Operations/customs/broker_client_auth.p12"
    openssl_pkcs12(
        customs_key,
        customs_cert,
        p12_out,
        P12_PASSWORD,
        "nordwind-customs-broker",
    )

    jks_out = DUMP / "IT/cloud/nw-portal.jks"
    generate_jks(jks_out, JKS_STORE_PASSWORD, "nordwind-portal")

    kdbx_out = DUMP / "Finance/nordwind_passwords.kdbx"
    generate_keepass(kdbx_out)

    generate_env_files()
    generate_hints()

    shutil.rmtree(tmp)

    print(
        "Vault pass complete (.kdbx, .p12, .jks, .env) — "
        f"KeePass master brute-forceable ({KEEPASS_MASTER})."
    )


if __name__ == "__main__":
    main()
