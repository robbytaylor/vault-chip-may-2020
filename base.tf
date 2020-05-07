resource vault_audit syslog {
  type    = "syslog"
  options = {}
}

resource vault_auth_backend userpass {
  type = "userpass"
}

resource vault_namespace namespace {
  for_each = toset(["security", "prod", "dev"])
  path     = each.key
}
