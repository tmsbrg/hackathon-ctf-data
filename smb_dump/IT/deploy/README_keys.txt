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
