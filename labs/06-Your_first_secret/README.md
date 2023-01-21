# Your first secret


Key/Value secrets engine is a generic key-value store used to store arbitrary secrets within the configured physical storage for Vault. Secrets written to Vault are encrypted and then written to backend storage. Therefore, the backend storage (in our case the Vault local FS) mechanism never sees the unencrypted value and doesn't have the means necessary to decrypt it without Vault.

You can interact with key/value secrets engine using the vault kv command. 

Get the command help.


```console
$ vault kv -help 
```

Key/Value secrets engine has version 1 and 2. The difference is that v2 provides versioning of secrets and v1 does not.

Let's enable the v2 KV secret engine:

```console
$ vault secrets enable -version=2 kv
Success! Enabled the kv secrets engine at: kv/
```

## Write/Read a secret

```console
$ vault kv put -mount=kv hello foo=world
== Secret Path ==
kv/data/hello

======= Metadata =======
Key                Value
---                -----
created_time       2023-01-20T20:33:45.536873043Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1
```

```console
$ vault kv get -mount=kv hello
== Secret Path ==
kv/data/hello

======= Metadata =======
Key                Value
---                -----
created_time       2023-01-20T20:33:45.536873043Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1

=== Data ===
Key    Value
---    -----
foo    world
```