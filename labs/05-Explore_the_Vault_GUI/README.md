# Explore the Vault GUI


Run a port-forward (in another terminal)

```console
$ kubectl port-forward -n vault vault-0 8200:8200
```

The point your browser to http://localhost:8200

You should see the Vault login page:

![](img/vault_login.png)

As the authentication **Method** choose **Token** and in the **Token** field insert your root token (see lab before).

The Vault home page should appear:

![](img/vault_home.png)