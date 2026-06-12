#!/usr/bin/env python3
"""Generate realistic SSH keys, TLS material, and SSH config cruft for the SMB dump.

Uses ssh-keygen and openssl — no fake PEM blobs.
"""
from __future__ import annotations

import base64
import os
import subprocess
import textwrap
from pathlib import Path

DUMP = Path(os.environ["DUMP"])

# Fixed seed comment strings (not secrets — realism / lore)
CI_DEPLOY_COMMENT = "ci-bot@gitlab.nordwind.internal"
LEGACY_RSA_COMMENT = "legacy-deploy@nw-dc01"
SHANGHAI_COMMENT = "li.wei@nw-sh01"


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(textwrap.dedent(content).strip() + "\n", encoding="utf-8")


def ssh_keygen(
    private_path: Path,
    key_type: str,
    comment: str,
    bits: int | None = None,
) -> None:
    private_path.parent.mkdir(parents=True, exist_ok=True)
    pub_path = Path(str(private_path) + ".pub")
    pub_path.unlink(missing_ok=True)
    private_path.unlink(missing_ok=True)

    cmd = [
        "ssh-keygen",
        "-t",
        key_type,
        "-f",
        str(private_path),
        "-N",
        "",
        "-C",
        comment,
        "-q",
    ]
    if bits is not None:
        cmd.extend(["-b", str(bits)])
    subprocess.run(cmd, check=True, capture_output=True)


def openssl_self_signed(
    key_path: Path,
    cert_path: Path,
    subject: str,
    days: int = 825,
) -> None:
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
            str(days),
            "-nodes",
            "-subj",
            subject,
        ],
        check=True,
        capture_output=True,
    )


def pem_block(pem_path: Path) -> str:
    return pem_path.read_text().strip()


def generate_ssh_deploy_keys() -> dict[str, Path]:
    """CI and legacy deploy keys — typical IT/deploy mirror."""
    deploy_dir = DUMP / "IT/deploy"
    ssh_dir = deploy_dir / ".ssh"

    ed25519 = deploy_dir / "ci_deploy_ed25519"
    ssh_keygen(ed25519, "ed25519", CI_DEPLOY_COMMENT)

    rsa_key = deploy_dir / "id_rsa"
    ssh_keygen(rsa_key, "rsa", LEGACY_RSA_COMMENT, bits=2048)

    # Shanghai ops backup key (found on shared drive copy)
    china_ssh = DUMP / "China_Office/.ssh"
    shanghai_key = china_ssh / "id_ed25519"
    ssh_keygen(shanghai_key, "ed25519", SHANGHAI_COMMENT)

    write_text(
        ssh_dir / "config",
        f"""\
        # Nordwind CI deploy agent — mirrored from nw-build01
        Host gitlab.nordwind.internal
          HostName gitlab.nordwind.internal
          User git
          IdentityFile ../ci_deploy_ed25519
          IdentitiesOnly yes

        Host registry.nordwind.internal
          User deploy
          IdentityFile ../ci_deploy_ed25519
          IdentitiesOnly yes

        Host nw-dc01.internal
          HostName nw-dc01.internal
          User deploy
          IdentityFile ../id_rsa
          IdentitiesOnly yes
          # Legacy RSA key — rotate after Q1 2025 migration
        """,
    )

    authorized = "\n".join(
        [
            Path(str(ed25519) + ".pub").read_text().strip(),
            Path(str(rsa_key) + ".pub").read_text().strip(),
            "# break-glass root — key removed 2023, line kept for audit",
        ]
    )
    write_text(ssh_dir / "authorized_keys", authorized + "\n")

    write_text(
        deploy_dir / "README_keys.txt",
        """\
        Nordwind Logistics — deploy key inventory (INTERNAL)
        ====================================================
        Mirror from nw-build01 before decommission.

        ci_deploy_ed25519     — GitLab CI + container registry (active)
        ci_deploy_ed25519.pub — install on gitlab.nordwind.internal
        id_rsa / id_rsa.pub   — legacy DC deploy (scheduled retirement)
        .ssh/config           — build agent defaults
        .ssh/authorized_keys  — inbound keys for deploy user (reference)

        Private keys must not leave build zone. This SMB copy is incident artifact only.
        Contact: d.jansen@nordwind-logistics.nl
        """,
    )

    return {
        "ed25519": ed25519,
        "rsa": rsa_key,
        "shanghai": shanghai_key,
    }


def generate_tls_material(vpn_ca_cert: Path) -> tuple[Path, Path]:
    """App deploy TLS key/cert and warehouse TLS decoy."""
    onboarding = DUMP / "IT/onboarding"
    openssl_self_signed(
        onboarding / "nw-deploy.key",
        onboarding / "nw-deploy.pem",
        "/CN=nw-portal-staging.nordwind.internal/O=Nordwind Logistics BV/C=NL",
        days=365,
    )

    warehouse = DUMP / "Operations/warehouse"
    openssl_self_signed(
        warehouse / "tls.key",
        warehouse / "server.crt",
        "/CN=warehouse-tools.nordwind.internal/O=Nordwind Logistics BV/C=NL",
        days=365,
    )

    archives = DUMP / "Archives/2019"
    openssl_self_signed(
        archives / "legacy_intranet.key",
        archives / "legacy_intranet.crt",
        "/CN=intranet-old.nordwind.internal/O=Nordwind Logistics BV/C=NL",
        days=1825,
    )

    return onboarding / "nw-deploy.pem", vpn_ca_cert


def generate_vpn_ca() -> Path:
    """CA for GlobalProtect .ovpn export."""
    vpn_dir = DUMP / "IT/onboarding"
    ca_key = vpn_dir / "vpn-ca.key"
    ca_cert = vpn_dir / "vpn-ca.crt"
    openssl_self_signed(
        ca_key,
        ca_cert,
        "/CN=Nordwind VPN CA/O=Nordwind Logistics BV/C=NL",
        days=825,
    )
    return ca_cert


def write_executive_ovpn(ca_cert: Path) -> None:
    ca_pem = pem_block(ca_cert)
    write_text(
        DUMP / "IT/onboarding/executive_globalprotect.ovpn",
        f"""\
        # Nordwind Logistics — GlobalProtect executive profile export
        # User: m.vandenberg | Profile: Executive-Global
        # IT note: PSK rotated 2024-03 — stored here during laptop migration

        client
        dev tun
        proto udp
        remote vpn.nordwind-logistics.nl 443
        resolv-retry infinite
        nobind
        persist-key
        persist-tun
        remote-cert-tls server
        cipher AES-256-GCM
        auth SHA256
        verb 3

        # Pre-shared key (legacy site-to-site fallback):
        # GP-Exec-PSK-2024-Rot

        <ca>
        {ca_pem}
        </ca>
        """,
    )


def write_kube_config(ca_cert: Path) -> None:
    ca_b64 = base64.b64encode(ca_cert.read_bytes()).decode()
    write_text(
        DUMP / "IT/cloud/.kube/config",
        f"""\
        apiVersion: v1
        kind: Config
        clusters:
        - cluster:
            certificate-authority-data: {ca_b64}
            server: https://k8s.nordwind.internal:6443
          name: nw-prod-eks
        contexts:
        - context:
            cluster: nw-prod-eks
            namespace: logistics
            user: deploy-sa
          name: nw-prod
        current-context: nw-prod
        users:
        - name: deploy-sa
          user:
            token: eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.BONUS{{kube_config_hunter}}.fake
        """,
    )


def main() -> None:
    DUMP.mkdir(parents=True, exist_ok=True)

    vpn_ca = generate_vpn_ca()
    write_executive_ovpn(vpn_ca)
    generate_ssh_deploy_keys()
    generate_tls_material(vpn_ca)
    write_kube_config(vpn_ca)

    print(
        "Crypto material generated (ssh-keygen ed25519/rsa, openssl x509, "
        "ovpn CA, kubeconfig CA data)."
    )


if __name__ == "__main__":
    main()
