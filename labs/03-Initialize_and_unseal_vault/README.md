# Initialize and unseal Vault

Initialize Vault

```console
$ kubectl exec vault-0 -- vault operator init                                             
Unseal Key 1: uKJ4N+4CxJkrYHD3SS9s+xIedLVnkaTqcVk4tpo6k/8e
Unseal Key 2: patP6/P8CtH/qYfst0rtc4atOHXnXMdiHTzUCq1JC0+N
Unseal Key 3: y75BFrd9ecdL7j/4mnXfpYCLwhi7bFy7AWfRk+75ViqT
Unseal Key 4: WDdxnkhKkcNsCIx/sdXK4/52RS17OoKCbDoljfJIoWnu
Unseal Key 5: NXvNjxQSbSPa13zHQnPtwlM+4xr/crj1oQz0HggZ8ZWE

Initial Root Token: hvs.zUnlNOFDFTeQxM8rQjza4l8r

Vault initialized with 5 key shares and a key threshold of 3. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 3 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated root key. Without at least 3 keys to
reconstruct the root key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.
```

Now unseal Vault using 3 of the 5 unseal keys displayed up above (unseal threshold)

```console
$ kubectl exec vault-0 -- vault operator unseal uKJ4N+4CxJkrYHD3SS9s+xIedLVnkaTqcVk4tpo6k/8e # Unseal Key 1
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    1/3
Unseal Nonce       a87ccedc-567b-c981-fcba-56882c49e9cb
Version            1.12.1
Build Date         2022-10-27T12:32:05Z
Storage Type       file
HA Enabled         false
```

```console
$ kubectl exec vault-0 -- vault operator unseal patP6/P8CtH/qYfst0rtc4atOHXnXMdiHTzUCq1JC0+N # Unseal Key 2                                              
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    2/3
Unseal Nonce       a87ccedc-567b-c981-fcba-56882c49e9cb
Version            1.12.1
Build Date         2022-10-27T12:32:05Z
Storage Type       file
HA Enabled         false
```

```console
$ kubectl exec vault-0 -- vault operator unseal y75BFrd9ecdL7j/4mnXfpYCLwhi7bFy7AWfRk+75ViqT                                            
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    5
Threshold       3
Version         1.12.1
Build Date      2022-10-27T12:32:05Z
Storage Type    file
Cluster Name    vault-cluster-5ce3fdd2
Cluster ID      f4e3ecd4-336c-58c7-eb0d-a5cb1b033fba
HA Enabled      false
```

If the unsealing is complete, the Vault pod should be in Ready state

```console
$ kubectl get pods                                                                          
NAME                                    READY   STATUS    RESTARTS   AGE
vault-0                                 1/1     Running   0          23m
vault-agent-injector-59b9c84fd8-5t8v8   1/1     Running   0          23m
```

The **vault-0** pod is now Ready, it means that Vault instance has been unsealed
