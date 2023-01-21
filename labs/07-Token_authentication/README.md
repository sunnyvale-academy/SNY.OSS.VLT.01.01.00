# Token authentication

Token authentication is automatically enabled. When you initialized the server, the output displayed a root token. 

The Vault CLI read the root token from the `$VAULT_TOKEN` environment variable. This root token can perform any operation within Vault because it is assigned the root policy (we will know more about policies later). 

One capability is to create new tokens.

Login as root 

```console
$ vault login $VAULT_TOKEN
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                hvs.xROa54CmUtgYMlDs94h3CTTf
token_accessor       SxOPR6or325736xw5riFouJv
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
```

Create a new token

```console
$ vault token create
Key                  Value
---                  -----
token                hvs.J87YulUbXfPef2u8lcyqOFYr
token_accessor       77IzxilT1lmAKD6kn8kbGiEm
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
```

The token is created and the output describes this token a table of keys and values. The created token is displayed.

This token is a child of the root token, and by default, it inherits the policies from its parent.

Token is the core authentication method. You can use the generated token to login with Vault, by copy and pasting it when prompted.

```console
$ vault login
Token (will be hidden): 

Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                hvs.J87YulUbXfPef2u8lcyqOFYr
token_accessor       77IzxilT1lmAKD6kn8kbGiEm
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
```

In turn, you can create a new token.

```console
$ vault token create
Key                  Value
---                  -----
token                hvs.hXbuQ70aFByRnJeAYsuqgnXt
token_accessor       OEWv6FkWCgvrwm4PwMXtDzEn
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
```

The token is created and displayed. Each token that Vault creates is unique.

When a token is no longer needed it can be revoked.

Revoke the first token you created.


```console
$ vault token revoke hvs.hXbuQ70aFByRnJeAYsuqgnXt
Success! Revoked token (if it existed)
```

The token has been revoked.

An attempt to login with the revoked token will result in an error.

```console
$ vault login hvs.hXbuQ70aFByRnJeAYsuqgnXt
Error authenticating: error looking up token: Error making API request.

URL: GET http://localhost:8200/v1/auth/token/lookup-self
Code: 403. Errors:

* permission denied
```

**Revoking a token will also revoke all tokens that were created by the token.**