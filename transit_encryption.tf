resource vault_mount transit-us {
  type  = "transit"
  path  = "transit"
  local = true
}

resource vault_transit_secret_backend_key us {
  backend = vault_mount.transit-us.path
  name    = "erp"
}

resource vault_mount transit-eu {
  provider = vault.eu

  type  = "transit"
  path  = "transit"
  local = true
}

resource vault_transit_secret_backend_key eu {
  provider = vault.eu

  backend = vault_mount.transit-eu.path
  name    = "erp"
}