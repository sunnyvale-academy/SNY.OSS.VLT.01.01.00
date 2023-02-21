# Custom secret engine plugin

## Prerequisites 

Having completed labs:

- [00 - Prerequisites](./labs/00-Prerequisites/README.md)

- [01 - Fork and clone this repo](./labs/01-Fork_and_clone_this_repo/README.md)

- [02 - Provision the environment](./labs/02-Provision_the_environment/README.md)

- [03 - Initialize and unseal Vault](./labs/03-Initialize_and_unseal_vault/README.md)

- [04 - Configure the Vault CLI](./labs/04-Configure_Vault_CLI/README.md)

- Vault running on x86 architecture since the plugin we are going to install is provided for this binary version

## Install the plugin

In this lab we will install the Enigma secret engine for Hashicorp Vault, a custom made secret engine that resables the Enigma cypher machine used in World War II.

Download the plugin's archive locally:

Copy the plugin on the Vault's pod

```console
$ kubectl cp enigma.1.0.0 vault-0:/usr/local/libexec/vault/enigma.1.0.0 -c vault -n vault
```

Register the plugin-in in Vault with the following command:

```console
$ curl -i --request PUT 192.168.39.152:30534/v1/sys/plugins/catalog/secret/enigma --header "X-Vault-Token: $(vault print token)" --data @- << EOF
{
  "type":"secret",
  "command":"$(tar tfz enigma.tar.gz)",
  "sha256":"$(./$(tar tfz enigma.tar.gz) hash)"
}
EOF
HTTP/1.1 204 No Content
Cache-Control: no-store
Content-Type: application/json
Strict-Transport-Security: max-age=31536000; includeSubDomains
Date: Mon, 20 Feb 2023 21:51:27 GMT
```

Check if the plugin has been registered:

```console
$ vault plugin list | grep enigma
enigma                               secret      n/a
```

kubectl exec -ti vault-0 -- apk add --allow-untrusted 

The plugin can now be enabled like any other secret engine:

```console
$ vault secrets enable enigma
```

