#!/usr/bin/env python3
"""Generate config-style filetypes from common secret-hunting lists (pastebin-style).

Adds extensions not covered by the core dump: .conf, .yaml, .yml, .toml,
.properties, .tfvars, .ovpn, .pem, .netrc, .npmrc, .env*, docker-compose,
vault.hcl, Oracle .ora, Tomcat server.xml, web.config, etc.

Some files hold bonus secrets; most are benign company cruft.
"""
from __future__ import annotations

import os
import textwrap
from pathlib import Path

DUMP = Path(os.environ["DUMP"])


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(textwrap.dedent(content).strip() + "\n", encoding="utf-8")


def bonus_secrets() -> None:
    """Secrets discoverable via rga / trufflehog on new extensions."""

    write_text(
        DUMP / "IT/legacy/redis.conf",
        """\
        # Nordwind Logistics — Redis cache (nw-cache01.internal)
        # Decommission scheduled Q2 2025 — still used by legacy portal

        bind 127.0.0.1
        port 6379
        requirepass RedisNw-Cache-8842!
        maxmemory 512mb
        maxmemory-policy allkeys-lru
        """,
    )

    write_text(
        DUMP / "IT/cloud/application.yml",
        """\
        # Spring Boot — Nordwind customer portal (staging)
        spring:
          application:
            name: nw-portal-staging
          datasource:
            url: jdbc:postgresql://nw-db-stg01.internal:5432/nordwind_staging
            username: portal_stg
            password: SpringStg_NwPortal_7xK!
          mail:
            host: smtp.sendgrid.net
            username: apikey
            password: SG.NwMail2024.xK9secret

        nordwind:
          wms:
            sync-endpoint: https://wms.nordwind-logistics.nl/api/v2
        """,
    )

    write_text(
        DUMP / "IT/cloud/terraform.tfvars",
        """\
        # Nordwind AWS migration — local tfvars (DO NOT COMMIT)
        aws_region = "eu-west-1"
        environment = "staging"
        vpc_cidr = "10.42.0.0/16"

        db_instance_class = "db.t3.medium"
        db_username = "nw_staging_admin"
        db_password = "TfNwDb_Staging_7xK!"

        s3_backup_bucket = "nw-tf-state-staging"
        tags = {
          company = "Nordwind Logistics BV"
          managed_by = "terraform"
        }
        """,
    )

    write_text(
        DUMP / "IT/deploy_logs/.npmrc",
        """\
        registry=https://registry.npmjs.org/
        @nordwind:registry=https://registry.nordwind.internal/
        //registry.nordwind.internal/:_authToken=npm_NwRegistry_8842token
        always-auth=true
        """,
    )

    write_text(
        DUMP / "Operations/warehouse/docker-compose.yml",
        """\
        # Local dev stack — Rotterdam DC warehouse tools (not production)
        version: "3.8"
        services:
          mongo:
            image: mongo:6
            environment:
              MONGO_INITDB_ROOT_USERNAME: nw_dev
              MONGO_INITDB_ROOT_PASSWORD: MongoNw-Docker-8842
            ports:
              - "27017:27017"
          redis:
            image: redis:7-alpine
            command: redis-server --requirepass devonly_notprod
        """,
    )

    write_text(
        DUMP / "IT/legacy/vault.hcl",
        """\
        # HashiCorp Vault — nw-vault01 (legacy on-prem, read-only mode)
        storage "file" {
          path = "/var/lib/vault/data"
        }

        listener "tcp" {
          address     = "127.0.0.1:8200"
          tls_disable = 1
        }

        # Unseal key shard 1 (break-glass binder — IT-7734):
        # VAULT_UNSEAL_KEY=VaultNw-Unseal-8842-xK9m

        ui = true
        """,
    )

    write_text(
        DUMP / "IT/deploy_logs/.env.staging",
        """\
        # Nordwind portal staging — copied from deploy server during incident mirror
        NODE_ENV=staging
        PORT=3000
        DATABASE_URL=postgresql://portal_stg:SpringStg_NwPortal_7xK!@nw-db-stg01:5432/nordwind_staging
        JWT_SECRET=jwt_NwStaging_NotForProd_8842
        STRIPE_PUBLISHABLE_KEY=pk_test_nottheliveone
        """,
    )


def benign_decoys() -> None:
    """Realistic config noise — no scoring secrets."""

    write_text(
        DUMP / "IT/legacy/tnsnames.ora",
        """\
        # Oracle TNS — legacy NWERP (decommissioned 2019)
        NWERP =
          (DESCRIPTION =
            (ADDRESS = (PROTOCOL = TCP)(HOST = nw-oracle-legacy.internal)(PORT = 1521))
            (CONNECT_DATA =
              (SERVER = DEDICATED)
              (SERVICE_NAME = NWERP.nordwind.internal)
            )
          )
        """,
    )

    write_text(
        DUMP / "IT/legacy/sqlnet.ora",
        """\
        # Oracle Net config — archival
        NAMES.DIRECTORY_PATH= (TNSNAMES, EZCONNECT)
        SSL_VERSION=1.2
        """,
    )

    write_text(
        DUMP / "IT/legacy/elasticsearch.yml",
        """\
        # Nordwind log cluster — nw-es01 (read-only archive)
        cluster.name: nordwind-logs
        node.name: nw-es01
        path.data: /var/lib/elasticsearch
        network.host: 127.0.0.1
        http.port: 9200
        xpack.security.enabled: true
        """,
    )

    write_text(
        DUMP / "IT/legacy/server.xml",
        """\
        <!-- Tomcat 9 — legacy intranet (decommissioned) -->
        <Server port="8005" shutdown="SHUTDOWN">
          <Service name="Catalina">
            <Connector port="8080" protocol="HTTP/1.1"/>
            <Engine name="Catalina" defaultHost="localhost">
              <Host name="localhost" appBase="webapps"/>
            </Engine>
          </Service>
        </Server>
        """,
    )

    write_text(
        DUMP / "Archives/2019/web.config",
        """\
        <?xml version="1.0" encoding="utf-8"?>
        <configuration>
          <system.web>
            <compilation debug="false" targetFramework="4.7.2"/>
            <authentication mode="Windows"/>
          </system.web>
          <appSettings>
            <add key="CompanyName" value="Nordwind Logistics BV"/>
            <add key="LegacyPortalUrl" value="https://intranet-old.nordwind.internal"/>
          </appSettings>
        </configuration>
        """,
    )

    write_text(
        DUMP / "HR/onboarding/application.properties",
        """\
        # AFAS HR connector — sandbox properties (no production credentials)
        afas.environment=sandbox
        afas.base-url=https://sandbox.afas.online
        afas.token=AFAS_SANDBOX_NOT_REAL_TOKEN
        nordwind.hr.export-path=/var/nordwind/hr/export
        """,
    )

    write_text(
        DUMP / "IT/cloud/bootstrap.yaml",
        """\
        # Spring Cloud bootstrap — cloud config client
        spring:
          application:
            name: nw-portal
          cloud:
            config:
              uri: https://config.nordwind.internal
              fail-fast: false
        """,
    )

    write_text(
        DUMP / "IT/cloud/consul.hcl",
        """\
        # Consul agent — nw-consul01 (service discovery)
        datacenter = "nw-rotterdam"
        data_dir = "/opt/consul/data"
        log_level = "INFO"
        server = false
        """,
    )

    write_text(
        DUMP / "IT/deploy_logs/pip.conf",
        """\
        [global]
        index-url = https://pypi.org/simple
        extra-index-url = https://pypi.nordwind.internal/simple

        [install]
        trusted-host = pypi.nordwind.internal
        """,
    )

    write_text(
        DUMP / "IT/deploy_logs/.pypirc",
        """\
        [distutils]
        index-servers =
            pypi
            nordwind

        [pypi]
        username = __token__
        password = pypi_fake_placeholder_not_real

        [nordwind]
        repository = https://pypi.nordwind.internal/
        username = ci
        password = not-a-real-pypi-password
        """,
    )

    write_text(
        DUMP / "Finance/NuGet.Config",
        """\
        <?xml version="1.0" encoding="utf-8"?>
        <configuration>
          <packageSources>
            <add key="nuget.org" value="https://api.nuget.org/v3/index.json"/>
            <add key="NordwindInternal" value="https://nuget.nordwind.internal/v3/index.json"/>
          </packageSources>
        </configuration>
        """,
    )

    write_text(
        DUMP / "IT/deploy_logs/settings.xml",
        """\
        <!-- Maven settings — CI build agent template -->
        <settings>
          <localRepository>/var/maven/repository</localRepository>
          <servers>
            <server>
              <id>nordwind-releases</id>
              <username>ci</username>
              <password>ci_build_placeholder</password>
            </server>
          </servers>
        </settings>
        """,
    )

    write_text(
        DUMP / "IT/deploy_logs/.netrc",
        """\
        machine ftp.vendor-backup.example.com
        login nordwind_backup
        password ftp_placeholder_not_real

        machine gitlab.nordwind.internal
        login ci-bot
        password gitlab_ci_placeholder
        """,
    )

    write_text(
        DUMP / "IT/backups/.pgpass",
        """\
        # PostgreSQL password file — format: host:port:database:user:password
        nw-db-backup01.internal:5432:nordwind_production:backup_ro:backup_ro_placeholder
        """,
    )

    write_text(
        DUMP / "IT/legacy/mongod.conf",
        """\
        # MongoDB — legacy route cache (read-only archive)
        storage:
          dbPath: /var/lib/mongo
        systemLog:
          destination: file
          path: /var/log/mongodb/mongod.log
        net:
          port: 27017
          bindIp: 127.0.0.1
        """,
    )

    write_text(
        DUMP / "IT/legacy/my.cnf",
        """\
        [client]
        host = nw-mysql-legacy.internal
        user = readonly
        password = mysql_readonly_placeholder

        [mysqld]
        datadir = /var/lib/mysql
        """,
    )

    write_text(
        DUMP / "IT/deploy_logs/gitlab-ci.yml",
        """\
        # Archived pipeline snippet — nw-portal (reference copy on SMB)
        stages:
          - test
          - build
          - deploy

        test:
          stage: test
          script:
            - npm ci
            - npm test

        deploy_staging:
          stage: deploy
          script:
            - echo "Deploy to staging — use vault for secrets"
          only:
            - develop
        """,
    )

    write_text(
        DUMP / "IT/deploy_logs/azure-pipelines.yml",
        """\
        # Azure DevOps — mirror of legacy pipeline (unused)
        trigger:
          - main

        pool:
          vmImage: ubuntu-latest

        steps:
          - script: echo "Nordwind Logistics CI placeholder"
            displayName: Smoke test
        """,
    )

    write_text(
        DUMP / "IT/cloud/nw-portal.toml",
        """\
        # Nordwind portal — deployment manifest (toml)
        [service]
        name = "nw-portal"
        port = 8080
        environment = "staging"

        [logging]
        level = "info"
        format = "json"
        """,
    )

    write_text(
        DUMP / "Operations/customs/openvpn.conf",
        """\
        # Site-to-site — customs broker VPN (decoy, no live creds)
        dev tun
        proto udp
        remote broker-vpn.example.com 1194
        resolv-retry infinite
        nobind
        persist-key
        persist-tun
        """,
    )

    write_text(
        DUMP / "Archives/2020/terraform.tfstate",
        """\
        {
          "version": 4,
          "terraform_version": "1.5.7",
          "serial": 42,
          "lineage": "nw-legacy-2020-state",
          "outputs": {},
          "resources": [
            {
              "type": "aws_s3_bucket",
              "name": "nw_archives",
              "instances": [
                {
                  "attributes": {
                    "bucket": "nw-archives-2020",
                    "region": "eu-west-1"
                  }
                }
              ]
            }
          ]
        }
        """,
    )


def main() -> None:
    DUMP.mkdir(parents=True, exist_ok=True)
    bonus_secrets()
    benign_decoys()
    print(
        "Filetype pass complete (.conf, .yaml, .yml, .toml, .properties, "
        ".tfvars, .ovpn, .pem, .key, .netrc, .npmrc, .env, vault.hcl, …)."
    )


if __name__ == "__main__":
    main()
