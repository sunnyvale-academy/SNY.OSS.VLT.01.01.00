# Policy-based authorization

## Prerequisites 

Having completed labs:

- [00 - Prerequisites](./labs/00-Prerequisites/README.md)

- [01 - Fork and clone this repo](./labs/01-Fork_and_clone_this_repo/README.md)

- [02 - Provision the environment](./labs/02-Provision_the_environment/README.md)

- [03 - Initialize and unseal Vault](./labs/03-Initialize_and_unseal_vault/README.md)

- [04 - Configure the Vault CLI](./labs/04-Configure_Vault_CLI/README.md)

- [06 - Your first secret](./labs/06-Your_first_secret/README.md)

## Introduction 

Policies in Vault control what a user can access. 

In the [Token authentication lab](../07-Token_authentication/README.md), you learned about authentication. This section is about authorization.

For authentication Vault has multiple options or methods (other than **Token authentication**, we will see other authentication methods later) that can be enabled and used. 

Vault always uses the same format for both authorization and policies. All auth methods map identities back to the core policies that are configured with Vault.

Policies are authored in HCL, but are JSON compatible. 

## Write a Policy

To write a policy, use vault policy write command.

You can create the policy named my-policy with the contents from stdin.

```console
$ 
```