# Manage auth methods broadly across Vault
path "auth/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "sys/namespaces/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "sys/audit"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "mysql-us/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "mysql-eu/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "aws/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Create, update, and delete auth methods
path "sys/auth/*"
{
  capabilities = ["create", "update", "delete", "sudo"]
}

# List auth methods
path "sys/auth"
{
  capabilities = ["read"]
}

# List existing policies
path "sys/policies/acl"
{
  capabilities = ["list"]
}

# Create and manage ACL policies
path "sys/policies/acl/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List, create, update, and delete key/value secrets
path "secret/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
  
path "transit/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage secrets engines
path "sys/mounts/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List existing secrets engines.
path "sys/mounts"
{
  capabilities = ["read"]
}

# Read health checks
path "sys/health"
{
  capabilities = ["read", "sudo"]
}

path "sys/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
