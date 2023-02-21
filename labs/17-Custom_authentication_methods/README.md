# Custom authentication methods

Vault support the installation of custom authentication method plugins. For this lab we will use the HashiCorp provided example (reference: https://github.com/hashicorp/vault-auth-plugin-example).

## Prerequisites 

Having completed labs:

- [00 - Prerequisites](./labs/00-Prerequisites/README.md)

- [01 - Fork and clone this repo](./labs/01-Fork_and_clone_this_repo/README.md)

- [02 - Provision the environment](./labs/02-Provision_the_environment/README.md)

- [03 - Initialize and unseal Vault](./labs/03-Initialize_and_unseal_vault/README.md)

- [04 - Configure the Vault CLI](./labs/04-Configure_Vault_CLI/README.md)

- Vault must be run on x86 architecture since the plugin used in this lab is compiled for Intel-based processors 

## Setup the plugin

The plugin binary file is shipped along this repo, just copy it on the Vault container, within the plugin folder:

```console
$ kubectl cp vault-auth-plugin-example vault-0:/usr/local/libexec/vault/vault-auth-plugin-example -c vault -n vault
```

Register the plugin in Vault

```console
$ vault plugin register \
    -sha256="$(shasum -a 256 vault-auth-plugin-example | cut -d ' ' -f 1)" \
    -command="vault-auth-plugin-example" \
    auth example-auth-plugin
Success! Registered plugin: example-auth-plugin
```
Now enable the plugin (a.k.a. mount the auth method)

```console
$ vault auth enable \
    -path="example" \
    -plugin-name="example-auth-plugin" plugin
Success! Enabled example-auth-plugin auth method at: example/
```

# Authenticating with the Shared Secret

To authenticate, the user supplies the shared secret:

```console
$ vault write auth/example/login password="super-secret-password"
Key                  Value
---                  -----
token                hvs.CAESIMKlB4SKFx2-86kYbYPGR18kGhH8DBhzqwBEtfJh3EbBGh4KHGh2cy5YM0lTOGFNSUpXa2tDY096TDNOZmdoOXQ
token_accessor       XLiYrvXsZ0Cv7LMJJJTe6Ziw
token_duration       30s
token_renewable      true
token_policies       ["default" "my-policy" "other-policy"]
identity_policies    []
policies             ["default" "my-policy" "other-policy"]
token_meta_fruit     banana
```

The response is a standard auth response with some token metadata.

You can try to login with this token

```console
$ unset VAULT_TOKEN && vault login hvs.CAESIMKlB4SKFx2-86kYbYPGR18kGhH8DBhzqwBEtfJh3EbBGh4KHGh2cy5YM0lTOGFNSUpXa2tDY096TDNOZmdoOXQ
Success! You are now authenticated. The token information displayed below.
...
```

This is an example Vault Plugin that is use for learning purposes, do not use in production!