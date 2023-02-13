
# OIDC authentication method

## Prerequisites 

Having completed labs:

- [00 - Prerequisites](./labs/00-Prerequisites/README.md)

- [01 - Fork and clone this repo](./labs/01-Fork_and_clone_this_repo/README.md)

- [02 - Provision the environment](./labs/02-Provision_the_environment/README.md)

- [03 - Initialize and unseal Vault](./labs/03-Initialize_and_unseal_vault/README.md)

- [04 - Configure the Vault CLI](./labs/04-Configure_Vault_CLI/README.md)

- An administrator access to an Okta account (Okta Developer Edition can be used for this lab).

## About this OIDC

Vault supports a number of auth methods for users or systems to prove their identity so that a token with appropriate policies can be obtained. 

Delegated authorization methods based on OAuth 2.0 are convenient for users and have become increasingly common and Vault supports OpenID Connect (OIDC) protocol (an identity layer on top of OAuth 2.0) to address the shortcomings of using OAuth 2.0 for establishing identity.

In this tutorial, you will create and configure the necessary resources in Okta to support the Vault OIDC auth method to allow policies to be assigned based on an Okta users group membership.

## Okta setup

If you do not have an Okta account, sign up for an Okta Developer Edition account at https://developer.okta.com/signup/.

To demonstrate authentication and policy assignment based on group membership you will create two users, and two groups in Okta.

1. Launch the Okta portal https://www.okta.com and login.

2. In the Okta dashboard, expand **Directory** in the left navigation menu and click **People**.

3. Click the **Add person** button and enter the following:

    **User type**: User

    **First name**: Thea

    **Last name**: Example

    **Username**: thea@example.com

    **Password**: I will set password

    **Enter password**: Password1!

    Uncheck the **User must change password on first login** checkbox

4. Click the **Save and Add Another** button and enter the following:

    **User type**: User

    **First name**: Bill

    **Last name**: Example

    **Username**: bill@example.com

    **Password**: I will set password

    **Enter password**: Password1!

    Uncheck the **User must change password on first login** checkbox

5. Click the **Save** button.

6. Click **Groups** in the left navigation menu.

7. Click the **Add Group** button, name the group `okta-group-vault-admins` and click the **Save** button.

8. Click the **Add Group** button, name the group `okta-group-vault-developer` and click the **Save** button.

9. Click on **okta-group-vault-admins** and click the **Assign People** button.

10. Click **Thea Example** to add that user to the **Members** list and click the **Save** button.

11. Click the **<- Back to Groups** link.

12. Click on **okta-group-vault-developer** and click the **Assign People** button.

13. Click **Bill Example** to add that user to the **Members** list and click the **Save** button.

You have created two users - Thea and Bill and assigned each to an Okta group `okta-group-vault-admins` and `okta-group-vault-developer`.


## Okta OIDC configuration

1. Expand **Security** in the left navigation menu and click **API**.

2. Click **default** and then click the Claims tab.

NOTE: If you are using the default authorization server for other applications, consider creating an additional authorization server specifically for Vault.


3. Click the **+ Add Claim** button and enter the following:

    **Name**: groups

    **Include in token type**: ID Token / Always

    **Value type**: Groups

    **Filter**: Starts with / okta-group-vault

    **Include in**: Click the The following scopes: radio button

    In the text box below **The following scopes**: type `profile` and click **profile** when it appears.

4. Click the **Create** button.

    You have updated the default authorization server to include groups with the token ID. Adding groups to the token ID will allow you to assign a Vault policy based on the Okta group membership.

5. Expand **Applications** in the left navigation menu and click Applications.

6. Click the **Create App Integration** button.

7. Click the **OIDC - OpenID Connect** radio button, a new section will appear.

8. Click the **Web Application** radio button and then click the **Next** button.

9. In the **App integration name** text box enter `hc-vault`.

10. In the **Grant type** section click the checkbox for **Implicit (hybrid)**.

11. Remove any existing **Sign-in redirect URIs** by clicking the **X** button.

12. Click the **+ Add URI** button - an empty text box will appear.

13. Retrieve and copy the address of the Vault cluster stored in the `VAULT_ADDR` environment variable.

    ```console
    $ echo $VAULT_ADDR   
    http://localhost:8200
    ```

14. Enter the address of your Vault cluster followed by `/ui/vault/auth/oidc/oidc/` callback.

15. Click the **+ Add URI** button again. Enter `http://localhost:8250/oidc/callback`

    This URI supports authenticating a user via the Vault CLI. For more information visit the [JWT/OIDC auth method](https://developer.hashicorp.com/vault/docs/auth/jwt) documentation.


16. Scroll to the bottom of the form.

17. In the **Assignments** section, click the **Limit access to selected groups** radio button.

18. In the **Selected group(s)** text box, enter `okta-group` and click **okta-group-vault-admins**.

19. Enter `okta-group` again and click **okta-group-vault-developer**.

20. Click the **Save** button.

21. Click the **Sign On** tab.

22. In the **OpenID Connect ID Token** section, click **Edit**

23. In the **Groups claim filter** text box enter `okta-group-vault`.

24. Click the **Save** button.

25. Click the **Okta API Scopes** tab.

26. Find **okta.groups.read** in the list and click **Grant**.

27. Find **okta.users.read.self** in the list and click **Grant**.

You have created an application integration that will support OIDC and assigned the user groups you created to this integration.

## Collect Okta configuration settings


1. Click the **General** tab.

2. Copy the **Client ID**.

3. Switch to your terminal and set an environment variable named `OKTA_CLIENT_ID`.

```console
$ export OKTA_CLIENT_ID=<CLIENT_ID>
```

4. Switch back to the Okta **hc-vault** configuration page and copy the **Client secret**.

5. Switch to your terminal and set an environment variable named `OKTA_CLIENT_SECRET`.

```console
$ export OKTA_CLIENT_SECRET=<CLIENT_SECRET>
```

6. Switch back to the Okta **hc-vault** configuration page. Click the user pull down menu at the top right of the Okta dashboard and copy the **Okta domain**.

7. Switch to your terminal and set an environment variable named `OKTA_DOMAIN`.

```console
$ export OKTA_DOMAIN=<OKTA_DOMAIN>
```

NOTE: The Okta specific environment variables were created to save the Okta configuration items that will be used later to configure Vault. It is not a requirement to have these environment variables set to use Okta with the Vault OIDC auth method beyond the scope of this tutorial.

8. Switch back to the Okta **hcp-vault** configuration page. Click the user pull down menu at the top right of the Okta dashboard and select **Sign out**.


## Configure Vault

You will now create a policy that allows read access to the k/v secrets engine for Bill (developer), and a policy that allows admin/super user access for Thea (admin).

Create the developer policy:

```console
$ vault policy write vault-policy-developer-read - << EOF
# Read permission on the k/v secrets
path "/kv/*" {
    capabilities = ["read", "list"]
}
EOF
Success! Uploaded policy: vault-policy-developer-read
```

Create the admin policy:

```console
$ vault policy write vault-policy-admin - << EOF
# Admin policy
path "*" {
        capabilities = ["sudo","read","create","update","delete","list","patch"]
}
EOF
Success! Uploaded policy: vault-policy-admin
```

## Enable OIDC auth method

```console
$ vault auth enable oidc
Success! Enabled oidc auth method at: oidc/
```

Create a role named `vault-role-okta-default`.

```console
$ vault write auth/oidc/role/vault-role-okta-default \
      bound_audiences="$OKTA_CLIENT_ID" \
      allowed_redirect_uris="$VAULT_ADDR/ui/vault/auth/oidc/oidc/callback" \
      allowed_redirect_uris="http://localhost:8250/oidc/callback" \
      user_claim="sub" \
      token_policies="default"
Success! Data written to: auth/oidc/role/vault-role-okta-default
```

The allowed_redirect_uris use the **Allowed Callback URLs** defined in the Okta OIDC configuration section. The `user_claim` sets the claim to use to uniquely identify the user.

Configure the oidc auth method.

```console
$ vault write auth/oidc/config \
         oidc_discovery_url="https://$OKTA_DOMAIN" \
         oidc_client_id="$OKTA_CLIENT_ID" \
         oidc_client_secret="$OKTA_CLIENT_SECRET" \
         default_role="vault-role-okta-default"
Success! Data written to: auth/oidc/config
```

The `oidc_discovery_url`, `oidc_client_id`, and `oidc_client_secret` are set to the variables defined in the Collect Okta configuration settings section.

The `default_role` is set to `vault-role-okta-default`. This role and default policy provide a limited set of access to anyone authenticating via Okta.

List the enabled auth methods.

```console
$ vault auth list
Path      Type     Accessor               Description                Version
----      ----     --------               -----------                -------
oidc/     oidc     auth_oidc_bf077227     n/a                        n/a
token/    token    auth_token_cc10dc93    token based credentials    n/a
```

When typing the command below, a browser window will pop up with the Okta login page.

Enter using **bill@example.com** and the password **Password1!** 

```console
$ vault login -method=oidc role="vault-role-okta-default"
Complete the login via your OIDC provider. Launching browser to:

    https://dev-93840644.okta.com/oauth2/v1/authorize?client_id=0oa8aum1b2NjQRMXa5d7&code_challenge=ZvGodK-vyFJc007vOeHM4NOuVfQZWkpb9cuQiA0iXBc&code_challenge_method=S256&nonce=n_yicBN2YD8yYlvyr8DunX&redirect_uri=http%3A%2F%2Flocalhost%3A8250%2Foidc%2Fcallback&response_type=code&scope=openid&state=st_f3Z6FPWHQ5So3t6aafrv


Waiting for OIDC authentication to complete...
WARNING! The VAULT_TOKEN environment variable is set! The value of this
variable will take precedence; if this is unwanted please unset VAULT_TOKEN or
update its value accordingly.

Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                hvs.CAESIMb6-NCUkVWTtndkwUR8ITLIx3p6iYKaFhTwLsgDvX37Gh4KHGh2cy5xU05SOTJBNHQxaUV6TnY4SW14MUd1ZFc
token_accessor       1qrErD19eh3C7BbSWaRv0siL
token_duration       768h
token_renewable      true
token_policies       ["default"]
identity_policies    []
policies             ["default"]
token_meta_role      vault-role-okta-default
```

If you type username and password correctly, the output shows the obtained token.

You were able to authenticate using Okta and received the default policy which provides limited access to Vault.

## Create an external Vault group

To assign different policies to different users based on their Okta group membership you will now configure Vault to match the Okta group membership of the user and assign a more permissive Vault role and policy.


Create a role named `vault-role-okta-group-vault-developer`.

```console
$ vault write auth/oidc/role/vault-role-okta-group-vault-developer \
      bound_audiences="$OKTA_CLIENT_ID" \
      allowed_redirect_uris="$VAULT_ADDR/ui/vault/auth/oidc/oidc/callback" \
      allowed_redirect_uris="http://localhost:8250/oidc/callback" \
      user_claim="sub" \
      token_policies="default" \
      oidc_scopes="groups" \
      groups_claim="groups"
Success! Data written to: auth/oidc/role/vault-role-okta-group-vault-developer
```

This role is defined similarly to the previously created role. The `default` policy is assigned to the token. Additional policies are assigned through any groups that the user claims to belong. The `groups_claim` field defines the value of `groups`. This value is the key in the ID token.


Create an external group, named `okta-group-vault-developer` with the `vault-policy-developer-read` policy.

```console
$ vault write identity/group name="okta-group-vault-developer" type="external" \
      policies="vault-policy-developer-read" \
      metadata=responsibility="okta-group-vault-developer"
Key     Value
---     -----
id      3b5bedc2-0c9c-a417-3f44-ea55cf8ffef3
name    okta-group-vault-developer
```

Create a variable named `GROUP_ID` to store the id of the `okta-group-vault-developer` group.

```console
$ export GROUP_ID=$(vault read -field=id identity/group/name/okta-group-vault-developer)
```

Create a variable named OIDC_AUTH_ACCESSOR to store the accessor of the oidc authentication method.

```console
$ export OIDC_AUTH_ACCESSOR=$(vault auth list -format=json  | jq -r '."oidc/".accessor')
```

Create a group alias named `okta-group-vault-developer`.

```console
$ vault write identity/group-alias name="okta-group-vault-developer" \
      mount_accessor="$OIDC_AUTH_ACCESSOR" \
      canonical_id="$GROUP_ID"
Key             Value
---             -----
canonical_id    3b5bedc2-0c9c-a417-3f44-ea55cf8ffef3
id              8e1fe8e9-d211-7b4f-794c-eff556b5b18f
```

The okta-group-vault-developer Vault group alias connects the oidc authentication method and the okta-group-vault-developer Vault group with the vault-policy-developer-read policy.


Log in with the oidc method as role of a **vault-role-okta-group-vault-developer**.

As before, a new browser window will popup with the Okta login page, just insert the user **bill@example.com** and password **Password1!**

```console
$ vault login -method=oidc role="vault-role-okta-group-vault-developer"
Complete the login via your OIDC provider. Launching browser to:

    https://dev-93840644.okta.com/oauth2/v1/authorize?client_id=0oa8aum1b2NjQRMXa5d7&code_challenge=6CGhLo_UCGQ1ASnst4Y_-TM_ImdfmK08E_VQNI_dG6I&code_challenge_method=S256&nonce=n_Z0JIz3pcJdYCnTbMTjwm&redirect_uri=http%3A%2F%2Flocalhost%3A8250%2Foidc%2Fcallback&response_type=code&scope=openid+groups&state=st_dAFYaSUz6okF6dbGwMbf


Waiting for OIDC authentication to complete...
WARNING! The VAULT_TOKEN environment variable is set! The value of this
variable will take precedence; if this is unwanted please unset VAULT_TOKEN or
update its value accordingly.

Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                hvs.CAESIEXwa1rt6iJdH5Opg6DkUD76Sgfphppo-lNx7s2AylX0Gh4KHGh2cy5xYXpsQ1V3NVJjNjUwNjJ3NFhVZnVmRUE
token_accessor       hlm62DFBfbltSpb2FQdvQMjE
token_duration       768h
token_renewable      true
token_policies       ["default"]
identity_policies    ["vault-policy-developer-read"]
policies             ["default" "vault-policy-developer-read"]
token_meta_role      vault-role-okta-group-vault-developer
```

If everything worked, the returned token inherits the `default` policy and is assigned the `vault-policy-developer-read` policy because the value `okta-group-vault-developer` matches the Okta group the user is assigned.