# Dynamic secrets

In the lab 06 you've experimented with the key/value secrets engine, now it is time to explore another feature of Vault: dynamic secrets.

Unlike the kv secrets where you had to put data into the store yourself, dynamic secrets are generated when they are accessed. Dynamic secrets do not exist until they are read, so there is no risk of someone stealing them or another client using the same secrets. Because Vault has built-in revocation mechanisms, dynamic secrets can be revoked immediately after use, minimizing the amount of time the secret existed.

## Prerequisites 

Having completed labs:

- [00 - Prerequisites](./labs/00-Prerequisites/README.md)

- [01 - Fork and clone this repo](./labs/01-Fork_and_clone_this_repo/README.md)

- [02 - Provision the environment](./labs/02-Provision_the_environment/README.md)

- [03 - Initialize and unseal Vault](./labs/03-Initialize_and_unseal_vault/README.md)

- [04 - Configure the Vault CLI](./labs/04-Configure_Vault_CLI/README.md)

- Having downlaoded and installed the aws CLI locally (see https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

# Confiture the Vault AWS secret engine

Suppose you need Vault to dynamically create secrets to let users access to AWS, in this case you need to activate the AWS secret engine:

```console
$ vault secrets enable -path=aws aws
Success! Enabled the aws secrets engine at: aws/
```

The AWS secrets engine is now enabled at aws/. Different secrets engines allow for different behavior. In this case, the AWS secrets engine generates dynamic, on-demand AWS access credentials.

After enabling the AWS secrets engine, you must configure it to authenticate and communicate with AWS. This requires privileged AWS account credentials.

If authenticating with an IAM user, set your AWS Access Key as an environment variable in the terminal that is running your Vault server:

```console
$ export AWS_ACCESS_KEY_ID=<aws_access_key_id>
$ export AWS_SECRET_ACCESS_KEY=<aws_secret_key>
```

Your keys must have the IAM permissions listed in the Vault documentation to perform the actions on the rest of this page.

Configure the AWS secrets engine.

```console
$ vault write aws/config/root \
    access_key=$AWS_ACCESS_KEY_ID \
    secret_key=$AWS_SECRET_ACCESS_KEY \
    region=us-east-1
Success! Data written to: aws/config/root
```

These credentials are now stored in this AWS secrets engine. The engine will use these credentials when communicating with AWS in future requests.

# Create a role

The next step is to configure a role. Vault knows how to create an IAM user via the AWS API, but it does not know what permissions, groups, and policies you want to attach to that user. This is where roles come in - a role in Vault is a human-friendly identifier to an action.

For example, this role will create AWS users with an attached IAM policy that enables all actions on EC2, but not IAM or other AWS services.

```
$ vault write aws/roles/my-role \
        credential_type=iam_user \
        policy_document=-<<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1426528957000",
      "Effect": "Allow",
      "Action": [
        "ec2:*"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
Success! Data written to: aws/roles/my-role
```

## Generate the secret

Now that the AWS secrets engine is enabled and configured with a role, you can ask Vault to generate an access key pair for that role by reading from aws/creds/:name, where :name corresponds to the name of an existing role:

```console
$  vault read aws/creds/my-role
Key                Value
---                -----
lease_id           aws/creds/my-role/iFvVaQ8Btf46ZnctIZIMmekT
lease_duration     768h
lease_renewable    true
access_key         AKIATPF13UZDGUY2TMA4EN
secret_key         xyzxyzxyzxyzxyzxyzxyzxyzxyzxyzxyzxyzxyzxyzxyz
security_token     <nil>
```

Success! The access and secret key can now be used to perform any EC2 operations within AWS. Notice that these keys are new, they are not the keys you entered earlier. If you were to run the command a second time, you would get a new access key pair. Each time you read from aws/creds/:name, Vault will connect to AWS and generate a new IAM user and key pair.

To test if the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY provided by Vault let you login on AWS, type the following command (make shure to substitute the placeholders with the actual values returned by Vault). 

```console
$ AWS_ACCESS_KEY_ID=<aws_access_key_id> AWS_SECRET_ACCESS_KEY=<aws_secret_key> aws ec2 describe-instances | jq
{
  "Reservations": []
}
```

If the output is similar to the one here above, the aws CLI logged in successfully with the credentials provided by Vault.

Copy the full path of this lease_id value found in the output. This value is used for renewal, revocation, and inspection.

## Revoke the secret

Vault will automatically revoke this credential after 768 hours (see lease_duration in the output), but perhaps you want to revoke it early. Once the secret is revoked, the access keys are no longer valid.

To revoke the secret, use vault lease revoke with the lease ID that was outputted from vault read when you ran it.

```console
$ vault lease revoke aws/creds/my-role/iFvVaQ8Btf46ZnctIZIMmekT
All revocation operations queued successfully!
```

Done! If you login to your AWS account, you will see that no IAM users exist. If you try to use the access keys that were generated, you will find that they no longer work.