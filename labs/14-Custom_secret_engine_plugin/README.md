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

```console
$ curl -OL https://github.com/ixe013/benigma/releases/latest/download/enigma.tar.gz -s
```

Copy the plugin on the Vault's pod

```console
$ kubectl cp enigma.tar.gz vault-0:/tmp/enigma.tar.gz -c vault -n vault
```

Extract Enigma's binary to the plug-in directory:

```console
$ kubectl exec -ti vault-0 -n vault -- tar xfzv /tmp/enigma.tar.gz -C /usr/local/libexec/vault
enigma.1.0.0
```

As any other custom secret engine, 

```console
$ curl -i --request PUT $VAULT_ADDR/v1/sys/plugins/catalog/secret/enigma --header "X-Vault-Token: $(vault print token)" --data @- << EOF
{
  "type":"secret",
  "command":"$(tar tfz enigma.tar.gz)",
  "sha256":"$(/usr/local/libexec/vault/$(tar tfz enigma.tar.gz) hash)"
}
EOF
```