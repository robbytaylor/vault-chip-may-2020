resource vault_policy admin {
  name   = "admin"
  policy = file("${path.root}/policies/admin.hcl")
}

resource vault_generic_endpoint admin {
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/userpass/users/admin"
  ignore_absent_fields = true

  lifecycle {
    ignore_changes = [data_json]
  }

  data_json = <<EOT
{
  "policies": [ "default", "admin"],
  "password": "${var.admin_password}"
}
EOT
}