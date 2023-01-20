# Configure the Vault CLI

Vault CLI can be downloaded at https://developer.hashicorp.com/vault/downloads

```console
export VAULT_TOKEN=$VAULT_ROOT_TOKEN
export VAULT_ADDR=http://$(minikube ip):30534
```

Login to Vault

```console
$ vault login $VAULT_TOKEN
```