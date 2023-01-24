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

We will create a Vault policy to protect writing to kv/data/hello (having completed the lab [06 - Your first secret](./labs/06-Your_first_secret/README.md) is mandatory).

Before stepping over, you must be authenticated against Vault with the root token:

```console
$ export VAULT_TOKEN=$(cat ../keys.json | jq -r ".root_token")
```

To write a policy, use vault policy write command.

You can create the policy named my-policy with the contents from stdin.

```console
$ vault policy write my-policy - << EOF
path "kv/data/*" {
  capabilities = ["create", "update"]
}

path "kv/data/hello" {
  capabilities = ["read"]
}
EOF
Success! Uploaded policy: my-policy
```

To make sure that your policy has been created type:

```console
$ vault policy list
default
my-policy
root
```

## Test the Policy

The policy you created provides limited management of secrets defined for the KV-V2 secrets engine. Policies are attached to tokens that Vault generates directly or through its various auth methods.

Create a token, add the my-policy policy, and set the token ID as the value of the VAULT_TOKEN environment variable for later use.

```console
$ export VAULT_TEST_TOKEN="$(vault token create -field token -policy=my-policy)"
```

Switch Vault CLI to use the VAULT_TEST_TOKEN just created.

```
$ export VAULT_TOKEN=$VAULT_TEST_TOKEN
```

You can validate that the token ID was exported properly, and has the correct policies attached.

```console
$ vault token lookup | grep policies
policies            [default my-policy]
```

The policy enables the create and update capabilities for every path within the kv/ engine except one.

The policy enables the create and update capabilities for every path within the vk/ engine except one.

Write a secret to the path kv/data/creds.

```console
$ vault kv put -mount=kv creds password="my-long-password"
== Secret Path ==
kv/data/creds

======= Metadata =======
Key                Value
---                -----
created_time       2023-01-24T14:49:16.754092963Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1
```

The secret is created successfully.

The policy only enables the read capability for the kv/data/hello path. An attempt to write to this path results in a "permission denied" error.

Attempt to write to the kv/data/hello path.

```console
$ vault kv put -mount=kv hello robot=beepboop
Error writing data to kv/data/hello: Error making API request.

URL: PUT http://localhost:8200/v1/kv/data/hello
Code: 403. Errors:

* 1 error occurred:
        * permission denied
```

The permission error is displayed.

If you try to delete the policy, a permission error occurs as well (you need permissions to write on the sys path in order to delete a policy).

```console
$ vault policy delete my-policy
Error deleting my-policy: Error making API request.

URL: DELETE http://localhost:8200/v1/sys/policies/acl/my-policy
Code: 403. Errors:

* 1 error occurred:
        * permission denied
```

To remove the policy, switch back the CLI to use the root token 

```console
$ export VAULT_TOKEN=$VAULT_ROOT_TOKEN
```

Now you can remove the policy

```console
$ vault policy delete my-policy 
Success! Deleted policy: my-policy   
```