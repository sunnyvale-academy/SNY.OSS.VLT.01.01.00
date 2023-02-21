# Rotate database credentials

Rotating database credentials is one of the main use cases impremented using Vault, let's try it on a PosgreSQL instance.

## Prerequisites 

Having completed labs:

- [00 - Prerequisites](./labs/00-Prerequisites/README.md)

- [01 - Fork and clone this repo](./labs/01-Fork_and_clone_this_repo/README.md)

- [02 - Provision the environment](./labs/02-Provision_the_environment/README.md)

- [03 - Initialize and unseal Vault](./labs/03-Initialize_and_unseal_vault/README.md)

- [04 - Configure the Vault CLI](./labs/04-Configure_Vault_CLI/README.md)

## Install the database

Before rotating its credentials we need to install a PostgreSQL on our Kuberentes instance.


Add the Bitnami helm repo

```console
$ helm repo add bitnami https://charts.bitnami.com/bitnami
"bitnami" has been added to your repositories
```

Refresh the repos index

```console
$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "hashicorp" chart repository
...Successfully got an update from the "bitnami" chart repository
Update Complete. ⎈Happy Helming!⎈
```

Let's install the database (for the sake of simplicity, we are installing the database on the Vault namespace, along with the actual Vault instance).

```console
$ helm install my-postgres bitnami/postgresql -n vault
NAME: my-postgres
LAST DEPLOYED: Tue Feb 21 10:21:49 2023
NAMESPACE: vault
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: postgresql
CHART VERSION: 12.2.1
APP VERSION: 15.2.0

** Please be patient while the chart is being deployed **

PostgreSQL can be accessed via port 5432 on the following DNS names from within your cluster:

    my-postgres-postgresql.vault.svc.cluster.local - Read/Write connection

To get the password for "postgres" run:

    export POSTGRES_PASSWORD=$(kubectl get secret --namespace vault my-postgres-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)

To connect to your database run the following command:

    kubectl run my-postgres-postgresql-client --rm --tty -i --restart='Never' --namespace vault --image docker.io/bitnami/postgresql:15.2.0-debian-11-r2 --env="PGPASSWORD=$POSTGRES_PASSWORD" \
      --command -- psql --host my-postgres-postgresql -U postgres -d postgres -p 5432

    > NOTE: If you access the container using bash, make sure that you execute "/opt/bitnami/scripts/postgresql/entrypoint.sh /bin/bash" in order to avoid the error "psql: local user with ID 1001} does not exist"

To connect to your database from outside the cluster execute the following commands:

    kubectl port-forward --namespace vault svc/my-postgres-postgresql 5432:5432 &
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U postgres -d postgres -p 5432

WARNING: The configured password will be ignored on new installation in case when previous Posgresql release was deleted through the helm command. In that case, old PVC will have an old password, and setting it through helm won't take effect. Deleting persistent volumes (PVs) will solve the issue.
```

Set the `$POSTGRES_PASSWORD` variable:

```console
$ export POSTGRES_PASSWORD=$(kubectl get secret --namespace vault my-postgres-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)
```

## Configure Vault

Enable the database secret engine

```console
$ vault secrets enable database
Success! Enabled the database secrets engine at: database/
```

Configure Vault with the proper plugin and connection information:

```console
$ vault write database/config/my-postgresql-database \
    plugin_name="postgresql-database-plugin" \
    allowed_roles="my-role" \
    connection_url="postgresql://{{username}}:{{password}}@my-postgres-postgresql.vault.svc.cluster.local:5432/postgres" \
    username="postgres" \
    password="$POSTGRES_PASSWORD"
Success! Data written to: database/config/my-postgresql-database
```

Configure a role that maps a name in Vault to an SQL statement to execute to create the database credential:

```console
$ vault write database/roles/my-role \
    db_name="my-postgresql-database" \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"
Success! Data written to: database/roles/my-role
```

## Usage

```console
$ vault read database/creds/my-role
Key                Value
---                -----
lease_id           database/creds/my-role/ZFeAzpPGclcPaoULQNLoJMNl
lease_duration     1h
lease_renewable    true
password           -ZjzeblshsqGQgB4qO1V
username           v-root-my-role-HBedAdOnF96OVzujSGrV-1676975908
```