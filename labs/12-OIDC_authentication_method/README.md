
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
path "/secret/*" {
    capabilities = ["read", "list"]
}
EOF
```

Create the admin policy:

```console
$ vault policy write vault-policy-admin - << EOF
# Admin policy
path "*" {
        capabilities = ["sudo","read","create","update","delete","list","patch"]
}
EOF
```

## Enable OIDC auth method

```console
$ vault auth enable oidc
```


```console
$
```