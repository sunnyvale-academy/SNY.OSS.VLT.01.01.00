# Initialize and unseal Vault

## Prerequisites 

Having completed labs:

- [00 - Prerequisites](./labs/00-Prerequisites/README.md)

- [01 - Fork and clone this repo](./labs/01-Fork_and_clone_this_repo/README.md)

- [02 - Provision the environment](./labs/02-Provision_the_environment/README.md)

## Initialize Vault

```console
$ kubectl exec -n vault vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > ../keys.json             
```

Set the VAULT_UNSEAL_KEY variable

```console
$ export VAULT_UNSEAL_KEY=$(cat ../keys.json | jq -r ".unseal_keys_b64[]")
```

## Unseal Vault

Now unseal Vault using the key (unseal threshold=1)

```console
$ kubectl exec vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.12.1
Build Date      2022-10-27T12:32:05Z
Storage Type    file
Cluster Name    vault-cluster-e7391ce8
Cluster ID      373e4e12-a7d8-5b5e-6c91-e6c04fc5e1bb
HA Enabled      false
```

The **vault-0** pod is now Ready, it means that Vault instance has been unsealed


## Re-initialization

In our lab environment, in the case you want to re-initialize Vault, just remove its PVC, the associated PV and the Helm release, for example:

```console
$ helm delete vault -n vault
release "vault" uninstalled
```

```console
$ kubectl delete pv pvc-44112c2d-f02b-41f3-9bf9-5a086c0d0a58
persistentvolume "pvc-44112c2d-f02b-41f3-9bf9-5a086c0d0a58" deleted
```

```console
$ kubectl delete pvc data-vault-0 -n vault                                                                                 
persistentvolumeclaim "data-vault-0" deleted
````

and restart from the previous lab.