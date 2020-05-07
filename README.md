# Vault Enterprise Setup

After running the Terraform to deploy primary, disaster recovery, and performance replication clusters, do the following to initialise the vaults and setup replication:

## Initialise the Vault and add the license

For all 3 clusters run:

```
vault operator init -recovery-shares=1 -recovery-threshold=1 -recovery-pgp-keys=keybase:hashicorpchip
vault write sys/license text=<license>
```

You should save the outputted recovery tokens to a safe place, for example AWS SSM Parameter Store

# Setup disaster recover

Use the root tokens generated above to run the following steps across the 3 clusters.

On the primary cluster run:

```
vault write sys/replication/dr/primary/secondary-token id="secondary"
```

Then using the token output above, on the DR cluster run:

```
vault write sys/replication/dr/secondary/enable token=<token>
```

# Setup performance replication

On the primary cluster run:

```
vault write sys/replication/performance/primary/secondary-token id=eucentral
```

Then using the token output above, on the performacne replication cluster run:

```
vault write sys/replication/performance/secondary/enable token=<token>
```

## Configure Vault

You can then use this Terraform configuration to setup the basic Vault config.

Using the root token for the primary cluster run:

```
terraform init
terraform apply -target=vault_audit.syslog -target=vault_auth_backend.userpass -target=vault_namespace.namespace -target=vault_policy.admin -target=vault_generic_endpoint.admin
```

This will:

* Enable the syslog audit device
* Enable userpass authentication backend
* Create 3 namespaces (dev, security, prod)
* Create an admin user in the userpass auth backend which can be used instead of the root token to run the rest of the Terraform configuration

With the admin user created you should revoke the root token on the primary cluster:

```
vault token revoke <root token>
```

Run the rest of the Terraform with the following command to setup the rest of the policies and local transit mount on the EU cluster:

```
VAULT_TOKEN=$(vault login -method=userpass username=admin -format=json | jq -r '.auth.client_token') TF_VAR_eu_token=$(VAULT_ADDR=<performance replication cluster address> vault login -method=userpass username=admin -format=json | jq -r '.auth.client_token') terraform apply
```

## Configure Vault Agent

Vault agent will need to be installed and configured on the application servers.

## US and Europe application servers

Follow the instructions in the [Vault Documentation](https://www.vaultproject.io/docs/install#precompiled-binaries) to download the Vault binary.

Add the following to `/etc/systemd/system/vault.server` to configure the Vault service:

```
[Unit]
Description="HashiCorp Vault"
Documentation=https://www.hashicorp.com/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault/agent.hcl
StartLimitIntervalSec=240
StartLimitBurst=3

[Service]
User=root
Group=root
ExecStart=/usr/local/bin/vault agent -config=/etc/vault/agent.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
Restart=on-failure
LimitNOFILE=65536
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=60
StartLimitIntervalSec=60
StartLimitBurst=3
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
```

## US application server

Add the following Vault agent configuration to `/etc/vault/agent.hcl`:

```
pid_file = "/opt/vault/pidfile"

vault {
    address = "<vault load balancer address>:8200"
}

auto_auth {
    method "aws" {
        mount_path = "auth/aws"

        config = {
            type = "iam"
            role = "erp-us"
        }
    }

    sink "file" {
        config = {
            path = "/opt/flask/token"
            mode = 0665
        }
    }
}

cache {
    use_auto_auth_token = true
}

listener "tcp" {
    address = "127.0.0.1:8100"
    tls_disable = true
}

template {
    command = "systemctl restart flask"
    source = "/opt/flask/mysqldbcreds.json.tpl"
    destination = "/opt/flask/mysqldbcreds.json"
}

template {
    command = "systemctl restart flask"
    source = "/opt/flask/awscreds.json.tpl"
    destination = "/opt/flask/awscreds.json"
}
```

Setup the mysql dynamic credentials template at `/opt/flask/mysqldbcreds.json.tpl`:

```
{{ with secret "mysql-us/creds/erp" }}
{
  "username": "{{ .Data.username }}",
  "password": "{{ .Data.password }}",
  "hostname": "<US RDS endpoint>"
}
{{ end }}
```

And setup the AWS dynamic credentials template at `/opt/flask/awscreds.json.tpl`:

```
{{ with secret "aws/creds/s3-read-write" }}
{
  "ACCESS_KEY": "{{ .Data.access_key }}",
  "SECRET_KEY": "{{ .Data.secret_key }}"
}
{{ end }}
```

To configure support for encryption / decryption, install `jq` and change the contents of `/opt/flask/vaulthook.sh` to:

```
#!/bin/bash
command=$1
shift 1

if [ $command = "encrypt" ]; then
  text=$(VAULT_TOKEN=$(cat /opt/flask/token) VAULT_ADDR=http://localhost:8100 vault write transit/encrypt/erp plaintext="$(base64 <<< $@)" -format=json | jq -r '.data.ciphertext')
else
  text=$(base64 --decode <<< $(VAULT_TOKEN=$(cat /opt/flask/token) VAULT_ADDR=http://localhost:8100 vault write transit/decrypt/erp ciphertext="$@" -format=json | jq -r '.data.plaintext'))
fi

echo $text
```

## EU application server

This is very similar to the process for the US application above, except the content of the files is slightly different to account for different roles and capabilities between the US and EU applications.

Add the following Vault agent configuration to `/etc/vault/agent.hcl`:

```
pid_file = "/opt/vault/pidfile"

vault {
    address = "<performance replicaiton cluster address>:8200"
}

auto_auth {
    method "aws" {
        mount_path = "auth/aws"
        config = {
            type = "iam"
            role = "erp-eu"
        }
    }

    sink "file" {
        config = {
            path = "/opt/flask/token"
            mode = 0665
        }
    }
}

cache {
    use_auto_auth_token = true
}

listener "tcp" {
    address = "127.0.0.1:8100"
    tls_disable = true
}

template {
    command = "systemctl restart flask"
    source = "/opt/flask/mysqldbcreds.json.tpl"
    destination = "/opt/flask/mysqldbcreds.json"
}

template {
    command = "systemctl restart flask"
    source = "/opt/flask/awscreds.json.tpl"
    destination = "/opt/flask/awscreds.json"
}
```

Setup the mysql dynamic credentials template at `/opt/flask/mysqldbcreds.json.tpl`:

```
{{ with secret "mysql-eu/creds/erp" }}
{
  "username": "{{ .Data.username }}",
  "password": "{{ .Data.password }}",
  "hostname": "<EU RDS endpoint>"
}
{{ end }}
```

And setup the AWS dynamic credentials template at `/opt/flask/awscreds.json.tpl`:

```
{{ with secret "aws/creds/s3-read-only" }}
{
  "ACCESS_KEY": "{{ .Data.access_key }}",
  "SECRET_KEY": "{{ .Data.secret_key }}"
}
{{ end }}
```

To configure support for encryption / decryption, install `jq` and change the contents of `/opt/flask/vaulthook.sh` to:

```
#!/bin/bash
command=$1
shift 1

if [ $command = "encrypt" ]; then
  text=$(VAULT_TOKEN=$(cat /opt/flask/token) VAULT_ADDR=http://localhost:8100 vault write transit/encrypt/erp plaintext="$(base64 <<< $@)" -format=json | jq -r '.data.ciphertext')
else
  text=$(base64 --decode <<< $(VAULT_TOKEN=$(cat /opt/flask/token) VAULT_ADDR=http://localhost:8100 vault write transit/decrypt/erp ciphertext="$@" -format=json | jq -r '.data.plaintext'))
fi

echo $text
```
