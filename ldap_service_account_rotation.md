# LDAP Service Account Rotation
This is the instruction for Claude Code to create a Hashicorp Vault demo flow.

# Requirement
I will use my local Macbook Pro as the demo machine.  The demo will be command line based. It utilises `demo-magic.sh` to create the pace and show the vault commands.

## OpenLDAP
OpenLDAP should be installed and run in a docker container and run in Docker Compose. 

## Vault Server
 - Latest Vault Enterprise server will be running in a separate docker container, also run in Docker Compose.
 - License file can be found in the local directory: vault.hclic
 - Vault server will be installed, licensed and unsealed.
 - Test the installation by running `vault status`
 - After it's successfully installed and started, print out its root token and server URL so I can use on my local laptop.


## Integration with Vault Secret Engine
 - A bind account should be created and be used by Vault to bind to LDAP server.
 - Vault is configured to use this binding account to talk to LDAP server
 - Docker Compose should take care of the communication between Vault server and LDAP server.

# Demo Flow
Each steps below is managed by `demo-magic.sh` with its `pe` command
- `vault write config` command to config the integration with LDAP
- Rotate the root credential as mentioned in https://developer.hashicorp.com/vault/docs/secrets/ldap#root-credential-rotation
- Schedule-based rotation as mentioned in https://developer.hashicorp.com/vault/docs/secrets/ldap#schedule-based-root-credential-rotation
- Configure a static role following https://developer.hashicorp.com/vault/docs/secrets/ldap#schedule-based-root-credential-rotation
- Rotate the static role password
- Show how to manually rotate the static role
- Configure dynamic role following https://developer.hashicorp.com/vault/docs/secrets/ldap#dynamic-credentials
- Show how to rotate the dynamic role manually using `vault read ldap/creds/dynamic-role`

