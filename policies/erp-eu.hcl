path "mysql-eu/creds/erp" {
  capabilities = ["read"]
}

path "transit/encrypt/erp" {
  capabilities = ["create", "update"]
}

path "transit/decrypt/erp" {
  capabilities = ["create", "update"]
}

path "aws/creds/s3-read-only" {
  capabilities = ["read"]
}
