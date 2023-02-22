export VAULT_ROOT_TOKEN=$(cat ../keys.json | jq -r ".root_token")
export VAULT_TOKEN=$VAULT_ROOT_TOKEN
export VAULT_ADDR=http://localhost:8200
export VAULT_UNSEAL_KEY=$(cat ../keys.json | jq -r ".unseal_keys_b64[]")
kubectl exec vault-0 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY