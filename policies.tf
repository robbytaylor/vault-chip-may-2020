resource vault_policy erp-us {
  name   = "erp-us"
  policy = file("${path.root}/policies/erp-us.hcl")
}

resource vault_policy erp-eu {
  name   = "erp-eu"
  policy = file("${path.root}/policies/erp-eu.hcl")
}
