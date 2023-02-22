# Vault as Certification Authority

Vault's PKI secrets engine can dynamically generate X.509 certificates on demand. This allows services to acquire certificates without going through the usual manual process of generating a private key and Certificate Signing Request (CSR), submitting to a Certificate Authority (CA), and then waiting for the verification and signing process to complete.

## Prerequisites 

Having completed labs:

- [00 - Prerequisites](./labs/00-Prerequisites/README.md)

- [01 - Fork and clone this repo](./labs/01-Fork_and_clone_this_repo/README.md)

- [02 - Provision the environment](./labs/02-Provision_the_environment/README.md)

- [03 - Initialize and unseal Vault](./labs/03-Initialize_and_unseal_vault/README.md)

- [04 - Configure the Vault CLI](./labs/04-Configure_Vault_CLI/README.md)

## Scenario introduction

In this lab, you are going to first generate a self-signed root certificate.

Then you are going to generate an intermediate certificate that is signed by the root. You can then create a role and generate a certificate for the test.example.com domain.

![](img/1.png)

## Generate Root CA

Enable the **pki** secrets engine at the **pki** path.

```console
$ vault secrets enable pki
Success! Enabled the pki secrets engine at: pki/
```

Tune the pki secrets engine to issue certificates with a maximum time-to-live (TTL) of 87600 hours.

```console
$ vault secrets tune -max-lease-ttl=87600h pki
Success! Tuned the secrets engine at: pki/
```

Generate the example.com root CA, give it an issuer name, and save its certificate in the file root_2022_ca.crt.

```console
$ vault write -field=certificate pki/root/generate/internal \
     common_name="example.com" \
     issuer_name="root-2022" \
     ttl=87600h > root_2022_ca.crt
```

This generates a new self-signed CA certificate and private key. Vault will automatically revoke the generated root at the end of its lease period (TTL);

List the issuer information for the root CA.

```console
$ vault list pki/issuers/
Keys
----
21ca18ce-a305-300b-92c6-585c020c07f6
```

You can read the issuer with its ID to get the certificates and other metadata about the issuer. Let's skip the certificate output, but list the issuer metadata and usage information.

```console
$ vault read pki/issuer/21ca18ce-a305-300b-92c6-585c020c07f6     | tail -n 6
leaf_not_after_behavior           err
manual_chain                      <nil>
ocsp_servers                      []
revocation_signature_algorithm    SHA256WithRSA
revoked                           false
usage                             crl-signing,issuing-certificates,ocsp-signing,read-only
```

Create a role for the root CA; creating this role allows for specifying an issuer when necessary for the purposes of this scenario. This also provides a simple way to transition from one issuer to another by referring to it by name.

```console
$ vault write pki/roles/2022-servers allow_any_name=true
Success! Data written to: pki/roles/2022-servers
```

Configure the CA and CRL URLs.

```console
$ vault write pki/config/urls \
     issuing_certificates="$VAULT_ADDR/v1/pki/ca" \
     crl_distribution_points="$VAULT_ADDR/v1/pki/crl"
Success! Data written to: pki/config/urls
```

## Generate intermediate CA

First, enable the pki secrets engine at the **pki_int** path.

```console
$ vault secrets enable -path=pki_int pki
Success! Enabled the pki secrets engine at: pki_int/
```

Tune the **pki_int** secrets engine to issue certificates with a maximum time-to-live (TTL) of 43800 hours.

```console
$ vault secrets tune -max-lease-ttl=43800h pki_int
Success! Tuned the secrets engine at: pki_int/
```

Execute the following command to generate an intermediate and save the CSR as pki_intermediate.csr.

```console
$ vault write -format=json pki_int/intermediate/generate/internal \
     common_name="example.com Intermediate Authority" \
     issuer_name="example-dot-com-intermediate" \
     | jq -r '.data.csr' > pki_intermediate.csr
```

Sign the intermediate certificate with the root CA private key, and save the generated certificate as intermediate.cert.pem.

```console
$ vault write -format=json pki/root/sign-intermediate \
     issuer_ref="root-2022" \
     csr=@pki_intermediate.csr \
     format=pem_bundle ttl="43800h" \
     | jq -r '.data.certificate' > intermediate.cert.pem
```

Once the CSR is signed and the root CA returns a certificate, it can be imported back into Vault.

```console
$ vault write pki_int/intermediate/set-signed certificate=@intermediate.cert.pem
Key                 Value
---                 -----
imported_issuers    [3438431b-ef04-10d0-4a04-512d8a350b09 341b702b-d675-8f7b-8078-2bc3b4003e35]
imported_keys       <nil>
mapping             map[341b702b-d675-8f7b-8078-2bc3b4003e35: 3438431b-ef04-10d0-4a04-512d8a350b09:f665a23b-9b46-370d-e8b3-4a122bb9264b]
```

## Create a role

Create a role named example-dot-com which allows subdomains, and specify the default issuer ref ID as the value of issuer_ref


```console
$ vault write pki_int/roles/example-dot-com \
      issuer_ref="$(vault read -field=default pki_int/config/issuers)" \
      allowed_domains="example.com" \
      allow_subdomains=true \
      max_ttl="720h"
Success! Data written to: pki_int/roles/example-dot-com
```

## Request certificates

Execute the following command to request a new certificate for the test.example.com domain based on the example-dot-com role.

```console
$ vault write pki_int/issue/example-dot-com common_name="test.example.com" ttl="24h"
Key                 Value
---                 -----
ca_chain            [-----BEGIN CERTIFICATE-----
MIIDpjCCAo6gAwIBAgIUfVyMgUFeyWcHJ8Jzs0iIMX4lbXkwDQYJKoZIhvcNAQEL
BQAwFjEUMBIGA1UEAxMLZXhhbXBsZS5jb20wHhcNMjMwMjIyMDcwNjMyWhcNMjgw
MjIxMDcwNzAyWjAtMSswKQYDVQQDEyJleGFtcGxlLmNvbSBJbnRlcm1lZGlhdGUg
QXV0aG9yaXR5MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3hmR7PY/
BGkKfZwDtZEGMxwx8PHvRKilWtfuWhENzTpR3a+D+OwuKvRoCapLI9/77Rp/5kep
DCxojjZ5rHIIw2uZk07hSJIBDVQAjxOlX5C1InAsgkt+godZWhmNb5xdtevh+34p
3pfXS0cb7sYY5NNC3aFxjGfWwBv8Ts9F5ju9V/FwpE0TaVViY+PsC5VTuK9ava63
I6L6MeIuUOMY3E73SJkgtmMgQKEazCHEBxn25jIvfLTXRMhQTG6IZx2ymmU9BWmj
vtDk3w87fTfBEXNxo7dX6dFQ71ATqA85Px2nrIMtOCMJH3EUrb6plB26rpe/25Yk
3rtNlSIcGDp+0QIDAQABo4HUMIHRMA4GA1UdDwEB/wQEAwIBBjAPBgNVHRMBAf8E
BTADAQH/MB0GA1UdDgQWBBQJFtJ6hwy0q8lAvpzHmfMw0dGC1TAfBgNVHSMEGDAW
gBRt4hMNJfTYZQKhmWrc7HM62bO7vDA7BggrBgEFBQcBAQQvMC0wKwYIKwYBBQUH
MAKGH2h0dHA6Ly9sb2NhbGhvc3Q6ODIwMC92MS9wa2kvY2EwMQYDVR0fBCowKDAm
oCSgIoYgaHR0cDovL2xvY2FsaG9zdDo4MjAwL3YxL3BraS9jcmwwDQYJKoZIhvcN
AQELBQADggEBAKtWsM/IZ6lGlRmDeQYqpe80IrZxYst2ph74/U61HrvrlD5KzT6V
D0z6ZppJPO3TuCRB+x7+lzrki0rJhheUKcy6OblU7jpw7ZgdP2sEoMUDG0swaNSW
zJ0XW8l6OjvoVRuaIUmecrXh5cXg4fcOq22Vz958le2AUeq5z33V6jKDbgQTO0M3
6czgdtcpC4kIZVmXKAYFMmxNI+phhKxwK5hqgNjEiww4nqWTOp3c7QiHglV2qCok
P4qiTjeLhWGeGRTz3aEUj/M0TBklNErL8tvLdMuc1a7Gutri51yVBxkD6CgzAKFB
xzvekJvGAWgavZ4CTv/sx5lmJnc5VJo9Y5I=
-----END CERTIFICATE----- -----BEGIN CERTIFICATE-----
MIIDNTCCAh2gAwIBAgIUKPqxVQ7ZZQZpDVJAeZn31JzYI1EwDQYJKoZIhvcNAQEL
BQAwFjEUMBIGA1UEAxMLZXhhbXBsZS5jb20wHhcNMjMwMjIyMDY1OTI2WhcNMzMw
MjE5MDY1OTU2WjAWMRQwEgYDVQQDEwtleGFtcGxlLmNvbTCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBAM7jydQSIAPXl7YKwsTXFldymC5Xhq0ilAI6zMlc
FgYHs5xTtxbLdPUOHDW4f9Gf86f1VT0dLg83GHqKg4KtRcDfLub6mm5P/BWUbOu3
xGs8t/n9OqizYDh5DfVPoz3PGOyqZFElun9E3e0Hkehme2O1Hebp3YOQxtvfqzgW
dLlAsuJynn9Xwbve46OKM6WnsO7wBgllsVND9IKqU2LGXgfuHy7bRzl6kq4sgGDT
Ix8GOtIqJRVBU35h5+5aHX0oYY0DU2YXa7wBBw2rQKbtUO28nfQ1qG69x6zkQuSd
AhTJIQes7bXvkMcE1aZngB9+qs/RatV3jZnfy27kCd3TNc8CAwEAAaN7MHkwDgYD
VR0PAQH/BAQDAgEGMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFG3iEw0l9Nhl
AqGZatzsczrZs7u8MB8GA1UdIwQYMBaAFG3iEw0l9NhlAqGZatzsczrZs7u8MBYG
A1UdEQQPMA2CC2V4YW1wbGUuY29tMA0GCSqGSIb3DQEBCwUAA4IBAQA4S1gDVofj
DmKX0kdEGuE4S/ZTd51z2FG6r1hBg41mhkCgVYPdrwu7Pq6z6Wg9A1+K2ZV2THZ1
50SyC6GQuFXRcSJK3LAH47UbtY0edzBIs1k92VZZzL92i1e8pcoCW1GNVu3rFLH9
2ou4IWOO5DA+pROIK1dRqSfvgf/AXCXyRiDo2rNnxOTNkeIt5I93Ol/lmhGig+Dj
/fQwciuh2dTmH1XxZlI3I0oS4Vc3bteKPgok3n6k+pf3AmSgABRBReWLwvI9fcKX
ZqwEtge72YdIrtcI/1CdyI8wDNVff4IJ2WckDjAHrRmHYG2E4q2j+lmOgXpB3QwA
YPyTRKE7jFd5
-----END CERTIFICATE-----]
certificate         -----BEGIN CERTIFICATE-----
MIIDZjCCAk6gAwIBAgIUExBDbiiAGxh+Adc2LxA+OLFK3ZQwDQYJKoZIhvcNAQEL
BQAwLTErMCkGA1UEAxMiZXhhbXBsZS5jb20gSW50ZXJtZWRpYXRlIEF1dGhvcml0
eTAeFw0yMzAyMjIwNzA5MjFaFw0yMzAyMjMwNzA5NTFaMBsxGTAXBgNVBAMTEHRl
c3QuZXhhbXBsZS5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCv
G0PA9gJMF88wu99U0ZRg3eA63ji7bK/J0dzF5NQAZm2Dw4Wa3Gh7JNOGPW5L/bch
Q66Lr9tLNPwWjd8XADHRAduJImpVNb3ZW3mVz5yJQEhYro2+R+zhxD1F7g9LROlA
4hoPOGUctjUqMG5xNLMYzWILQVdHBQRcidF7B59bEnklArBHVpsOEnc1HYPe7UjK
cS/ubt6pPiLtqPYVLgxFSR67i2XPzQ9n3DpMJ7UPLrFphZOWPZTT61dN1QeHI1c3
9GeukEocWWrmk4lhkP3Adfb+r5cAGTmjSDQ5lB/+QuCaEgOkAqFrMDLEeA0cFNMD
HXQRd/7WEBnqzflsEtR/AgMBAAGjgY8wgYwwDgYDVR0PAQH/BAQDAgOoMB0GA1Ud
JQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAdBgNVHQ4EFgQU4hraeWwRyw1qVhXc
TxIMggFDV9swHwYDVR0jBBgwFoAUCRbSeocMtKvJQL6cx5nzMNHRgtUwGwYDVR0R
BBQwEoIQdGVzdC5leGFtcGxlLmNvbTANBgkqhkiG9w0BAQsFAAOCAQEAiWQgj3bF
8kefSB6hHarMvoZnUo1iTt1S0eXf4eI/E4XRYc9sIU+5kT31BKw9UqX6xKQcLx8X
OwvChTYRAxJ6fHAW08HLbYXygA03ihibw+14Ya4fp2caF8PmbVp8CBfrVU3KhKPi
gXVeaWxCa8rlvLuThWMoMeuzXhCXt4edqKq/p4ZU+FORP9KzsYw/7z5s8Zf6Bh+U
VsgeYlDJE+7cOvNjqACUixpGr6i8IQrMe6cP6ctctnCV1K/5ANTccGlGaNYHzynz
HnWU951JkCrTGFyApQKaIJZHlRX3uVRjUXz28isvZu7LL+pX6YJwXKZqGtCEmO2N
NIP5/haHtX9tTQ==
-----END CERTIFICATE-----
expiration          1677136191
issuing_ca          -----BEGIN CERTIFICATE-----
MIIDpjCCAo6gAwIBAgIUfVyMgUFeyWcHJ8Jzs0iIMX4lbXkwDQYJKoZIhvcNAQEL
BQAwFjEUMBIGA1UEAxMLZXhhbXBsZS5jb20wHhcNMjMwMjIyMDcwNjMyWhcNMjgw
MjIxMDcwNzAyWjAtMSswKQYDVQQDEyJleGFtcGxlLmNvbSBJbnRlcm1lZGlhdGUg
QXV0aG9yaXR5MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3hmR7PY/
BGkKfZwDtZEGMxwx8PHvRKilWtfuWhENzTpR3a+D+OwuKvRoCapLI9/77Rp/5kep
DCxojjZ5rHIIw2uZk07hSJIBDVQAjxOlX5C1InAsgkt+godZWhmNb5xdtevh+34p
3pfXS0cb7sYY5NNC3aFxjGfWwBv8Ts9F5ju9V/FwpE0TaVViY+PsC5VTuK9ava63
I6L6MeIuUOMY3E73SJkgtmMgQKEazCHEBxn25jIvfLTXRMhQTG6IZx2ymmU9BWmj
vtDk3w87fTfBEXNxo7dX6dFQ71ATqA85Px2nrIMtOCMJH3EUrb6plB26rpe/25Yk
3rtNlSIcGDp+0QIDAQABo4HUMIHRMA4GA1UdDwEB/wQEAwIBBjAPBgNVHRMBAf8E
BTADAQH/MB0GA1UdDgQWBBQJFtJ6hwy0q8lAvpzHmfMw0dGC1TAfBgNVHSMEGDAW
gBRt4hMNJfTYZQKhmWrc7HM62bO7vDA7BggrBgEFBQcBAQQvMC0wKwYIKwYBBQUH
MAKGH2h0dHA6Ly9sb2NhbGhvc3Q6ODIwMC92MS9wa2kvY2EwMQYDVR0fBCowKDAm
oCSgIoYgaHR0cDovL2xvY2FsaG9zdDo4MjAwL3YxL3BraS9jcmwwDQYJKoZIhvcN
AQELBQADggEBAKtWsM/IZ6lGlRmDeQYqpe80IrZxYst2ph74/U61HrvrlD5KzT6V
D0z6ZppJPO3TuCRB+x7+lzrki0rJhheUKcy6OblU7jpw7ZgdP2sEoMUDG0swaNSW
zJ0XW8l6OjvoVRuaIUmecrXh5cXg4fcOq22Vz958le2AUeq5z33V6jKDbgQTO0M3
6czgdtcpC4kIZVmXKAYFMmxNI+phhKxwK5hqgNjEiww4nqWTOp3c7QiHglV2qCok
P4qiTjeLhWGeGRTz3aEUj/M0TBklNErL8tvLdMuc1a7Gutri51yVBxkD6CgzAKFB
xzvekJvGAWgavZ4CTv/sx5lmJnc5VJo9Y5I=
-----END CERTIFICATE-----
private_key         -----BEGIN RSA PRIVATE KEY-----
MIIEpgIBAAKCAQEArxtDwPYCTBfPMLvfVNGUYN3gOt44u2yvydHcxeTUAGZtg8OF
mtxoeyTThj1uS/23IUOui6/bSzT8Fo3fFwAx0QHbiSJqVTW92Vt5lc+ciUBIWK6N
vkfs4cQ9Re4PS0TpQOIaDzhlHLY1KjBucTSzGM1iC0FXRwUEXInRewefWxJ5JQKw
R1abDhJ3NR2D3u1IynEv7m7eqT4i7aj2FS4MRUkeu4tlz80PZ9w6TCe1Dy6xaYWT
lj2U0+tXTdUHhyNXN/RnrpBKHFlq5pOJYZD9wHX2/q+XABk5o0g0OZQf/kLgmhID
pAKhazAyxHgNHBTTAx10EXf+1hAZ6s35bBLUfwIDAQABAoIBAQCdJA2Yk+0Z1mAU
LvVLy8ypZVP94EDvSakzp4bFfQYX2dO75HH4uIV2xWSh2m0p+uUmD/QK3WUhx8nW
f7jNjlomY9Fc7qqYD2NxNNsW6zpiHXMPSo5fTXKyZIZMREgrVwswM/gI4qYyrv1l
ABOMuitjPaUXzqqBTGpOlUuNahjDA4MfImZrfRvUALU8ybNJ7FacgZ0qlQWyTYfK
kEAq/LWFkbUGZV8xLSqHZh2EeXsTe75NxsTJOMEKmA+5o9Dx0r+fsGgtjw7O3OzV
VZrNdxNPSUWAYjHyrV/7G+CHsFACIXE9KQmGqCnJ0yds6NDx9Esl4dgK1jG4jefB
qiH/8p2xAoGBAOJ3TnXpvJlJ3s/PBIajVi0wihKKg7Q6bX+ijnlAUHcFZxCvzLE6
rtjv4eZ7mNuMA0LhJS0DXjMv6sdXeN6NqyNHo0t/twuE4xjt8B06xBHS3KObLenz
ir3zIhhc6ZEMd7cf9C4kPeTcKjtbLxSafbg0QqF5BUfBG5+8pljj3bZpAoGBAMXx
SqzPM9UuL20ifHVkk+FM/PrxCgwph+OzdywqLjmH6opKiVIC7IyA1B57W1GuAZJv
wKjx54qudQYfyrAIujTcEC9C6fUji2OTvTHWSsCx2sDXQKuNYCvLiYPLkJqkkakC
xVWrAqckn80gyvVZ+GA2Wu367/odobduHFQnS2anAoGBAM24DRkFq6IfvXxOlNDt
XSINvs8a7orwrHlOJFg2uSF1UeuRlsLECQLd3fpt+iwtouTE+u1J6u9ars5IQm8A
iB6zO74glRmsrFMACaezs1pxjqY8F9g2uKjWTPmOpUly5uj96OVlXKgh62ch7MGt
mViUeJaQBeDppXtUdlO3IrdJAoGBAMJg6gj7TJYqzY3pULjjNMkJlmBC9a/t1LEJ
Gp03Kr96NhrpiSINFwf+ts7cKlfyfT61GUeOjebE3MxPyfXGDD0+YXJXznHZHteB
TEg1fKDvxraaarpMkcVQEdFnxK/nrdZ/jxNKZMeIEpkYe9YmLN8mYXLTenduQ9Fi
gtUs5UF/AoGBALKq7zYvnAI96phqi1ai5/luvpjFQrieRp8HJwHxfpBNZe9mPQCd
TCZ4kNktscEg2nmnDyFiGaNX2lXA/68+txjRxh/wc2ghhi+2X7pNvuht/IuBZeqj
kN6twTF3drhbTFTbVUl5V+0z68vo0q5d1K+F3+KFwcQ8soeYztGFYk1a
-----END RSA PRIVATE KEY-----
private_key_type    rsa
serial_number       13:10:43:6e:28:80:1b:18:7e:01:d7:36:2f:10:3e:38:b1:4a:dd:94
```

The response contains the PEM-encoded private key, key type and certificate serial number.

```console
$ vault write pki_int/issue/example-dot-com common_name="test.sunnyvale.it" ttl="24h"
Error writing data to pki_int/issue/example-dot-com: Error making API request.

URL: PUT http://localhost:8200/v1/pki_int/issue/example-dot-com
Code: 400. Errors:

* common name test.sunnyvale.it not allowed by this role
```