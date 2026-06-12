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
