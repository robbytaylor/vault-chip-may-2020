resource vault_mount us {
  path = "mysql-us"
  type = "database"
}

resource vault_mount eu {
  path = "mysql-eu"
  type = "database"
}

resource vault_database_secret_backend_connection mysql-us {
  backend       = vault_mount.us.path
  name          = "erp"
  allowed_roles = ["erp"]

  mysql {
    connection_url = "foo:foobarbaz@tcp(${var.primary_rds_hostname}:3306)/"
  }
}

resource vault_database_secret_backend_role mysql-us {
  backend               = vault_mount.us.path
  name                  = "erp"
  db_name               = vault_database_secret_backend_connection.mysql-us.name
  default_ttl           = 5
  max_ttl               = 10
  creation_statements   = ["CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';"]
  revocation_statements = ["DROP USER '{{name}}'@'%'"]
}

resource vault_database_secret_backend_connection mysql-eu {
  backend       = vault_mount.eu.path
  name          = "erp"
  allowed_roles = ["erp"]

  mysql {
    connection_url = "foo:foobarbaz@tcp(${var.eu_rds_hostname}:3306)/"
  }
}

resource vault_database_secret_backend_role mysql-eu {
  backend               = vault_mount.eu.path
  name                  = "erp"
  db_name               = vault_database_secret_backend_connection.mysql-eu.name
  default_ttl           = 5
  max_ttl               = 10
  creation_statements   = ["CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';"]
  revocation_statements = ["DROP USER '{{name}}'@'%'"]
}
