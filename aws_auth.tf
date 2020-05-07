resource vault_auth_backend aws {
  type = "aws"
}

resource vault_aws_auth_backend_role erp-us {
  backend           = vault_auth_backend.aws.path
  role              = "erp-us"
  auth_type         = "iam"
  bound_account_ids = [var.aws_account_id]

  inferred_entity_type = "ec2_instance"
  inferred_aws_region  = "us-east-1"
  token_ttl            = 5
  token_max_ttl        = 120
  token_policies       = ["default", "erp-us"]
}

resource vault_aws_auth_backend_role erp-eu {
  backend           = vault_auth_backend.aws.path
  role              = "erp-eu"
  auth_type         = "iam"
  bound_account_ids = [var.aws_account_id]

  inferred_entity_type = "ec2_instance"
  inferred_aws_region  = "eu-central-1"
  token_ttl            = 5
  token_max_ttl        = 120
  token_policies       = ["default", "erp-eu"]
}
