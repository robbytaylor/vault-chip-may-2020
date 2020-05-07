resource vault_aws_secret_backend aws {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource vault_aws_secret_backend_role s3-rw {
  backend         = vault_aws_secret_backend.aws.path
  name            = "s3-read-write"
  credential_type = "iam_user"

  policy_document = <<-EOT
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": "s3:*",
          "Resource": [
            "arn:aws:s3:::${var.bucket}",
            "arn:aws:s3:::${var.bucket}/*"
          ]
        }
      ]
    }
EOT
}

resource vault_aws_secret_backend_role s3-ro {
  backend         = vault_aws_secret_backend.aws.path
  name            = "s3-read-only"
  credential_type = "iam_user"

  policy_document = <<-EOT
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
              "s3:Get*",
              "s3:List*"
          ],
          "Resource": [
            "arn:aws:s3:::${var.bucket}",
            "arn:aws:s3:::${var.bucket}/*"
          ]
        }
      ]
    }
EOT
}
