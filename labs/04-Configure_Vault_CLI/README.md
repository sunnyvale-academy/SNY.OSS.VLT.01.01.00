# Configure the Vault CLI

## Prerequisites 

Having completed labs:

- [00 - Prerequisites](./labs/00-Prerequisites/README.md)

- [01 - Fork and clone this repo](./labs/01-Fork_and_clone_this_repo/README.md)

- [02 - Provision the environment](./labs/02-Provision_the_environment/README.md)

- [03 - Initialize and unseal Vault](./labs/03-Initialize_and_unseal_vault/README.md)

## Configure the CLI

Vault CLI can be downloaded at https://developer.hashicorp.com/vault/downloads

```console
$ export VAULT_ROOT_TOKEN=$(cat ../keys.json | jq -r ".root_token")
$ export VAULT_TOKEN=$VAULT_ROOT_TOKEN
$ export VAULT_ADDR=http://localhost:8200
```
We expect that the three variables listed here before are set in the terminal you use for the labs from now on.

Run a port-forward (in another terminal)

```console
$ kubectl port-forward -n vault vault-0 8200:8200
```


Login to Vault (the Vault URL is taken from the VAULT_ADDR variable)

```console
$ vault login $VAULT_TOKEN
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                hvs.xROa54CmUtgYMlDs94h3CTTf
token_accessor       SxOPR6or325736xw5riFouJv
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
```

If you have successfully logged in, it means that the Vault CLI is configured correctly (remember to set the VAULT_TOKEN and VAULT_ADDRESS variable if you change terminal).