#!/bin/bash

# HashiCorp Vault LDAP Service Account Rotation Demo
# Using demo-magic.sh for paced demonstrations

# Download demo-magic.sh if not present
if [ ! -f "demo-magic.sh" ]; then
    echo "Downloading demo-magic.sh..."
    curl -s https://raw.githubusercontent.com/paxtonhare/demo-magic/master/demo-magic.sh -o demo-magic.sh
    chmod +x demo-magic.sh
fi

# Source demo-magic
. ./demo-magic.sh

# Set demo speed
TYPE_SPEED=50
DEMO_PROMPT="${GREEN}➜ ${CYAN}\W ${COLOR_RESET}"

# Vault configuration
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="myroot"

clear

# Demo title
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║           HashiCorp Vault LDAP Service Account Rotation       ║"
echo "║                            Demo                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${COLOR_RESET}"
echo ""

echo -e "${YELLOW}This demo shows how to use HashiCorp Vault for LDAP service account rotation${COLOR_RESET}"
echo ""
wait

# Check Vault status
echo -e "${BLUE}### Step 1: Verify Vault Status${COLOR_RESET}"
pe "vault status"
wait

# Enable and show LDAP secrets engine
echo -e "${BLUE}### Step 2: Enable LDAP Secrets Engine${COLOR_RESET}"
echo "First, let's enable the LDAP secrets engine if it's not already enabled"
pe "vault secrets list | grep ldap || vault secrets enable ldap"
wait

# Configure LDAP integration
echo -e "${BLUE}### Step 3: Configure LDAP Integration${COLOR_RESET}"
echo "This configures Vault to connect to our OpenLDAP server using a dedicated bind user"
pe "vault write ldap/config \\
    binddn=\"cn=vault-bind,ou=people,dc=demo,dc=hashicorp,dc=com\" \\
    bindpass=\"vaultbind123\" \\
    url=\"ldap://openldap:389\" \\
    userdn=\"ou=people,dc=demo,dc=hashicorp,dc=com\""
wait

# Verify configuration
echo -e "${BLUE}### Step 4: Verify LDAP Configuration${COLOR_RESET}"
pe "vault read ldap/config"
wait

# Root credential rotation
echo -e "${BLUE}### Step 5: Root Credential Rotation${COLOR_RESET}"
echo "Root credential rotation requires the bind user to have LDAP search permissions"
echo "We have configured LDAP ACLs to allow vault-bind user to search and modify passwords"
echo "Let's verify our vault-bind configuration supports root rotation:"
pe "vault read ldap/config"
echo "Now rotate the root credentials using the properly configured vault-bind user:"
pe "vault write -f ldap/rotate-root"
wait

# Schedule-based root credential rotation
echo -e "${BLUE}### Step 6: Schedule-based Root Credential Rotation${COLOR_RESET}"
echo "Configure automatic rotation every 24 hours with a password policy"
echo "Note: This sets the bind account to rotate automatically using the demo-policy"
pe "vault write ldap/config \\
    binddn=\"cn=vault-bind,ou=people,dc=demo,dc=hashicorp,dc=com\" \\
    url=\"ldap://openldap:389\" \\
    userdn=\"ou=people,dc=demo,dc=hashicorp,dc=com\" \\
    password_policy=\"demo-policy\" \\
    rotate_period=\"24h\""
wait

# Create password policy
echo -e "${BLUE}### Step 7: Create Password Policy${COLOR_RESET}"
pe "vault write sys/policies/password/demo-policy policy=@password-policy.hcl"
wait

# Configure static role
echo -e "${BLUE}### Step 8: Configure Static Role${COLOR_RESET}"
echo "Using our properly configured vault-bind user for static role management"
echo "The vault-bind user has the necessary LDAP ACLs to manage service account passwords"
pe "vault write ldap/static-role/service-account \\
    dn=\"cn=service-account,ou=people,dc=demo,dc=hashicorp,dc=com\" \\
    username=\"service-account\" \\
    rotation_period=\"60s\""
wait

# Read static role credentials
echo -e "${BLUE}### Step 9: Read Static Role Credentials${COLOR_RESET}"
pe "vault read ldap/static-cred/service-account"
wait

# Manual static role rotation
echo -e "${BLUE}### Step 10: Manual Static Role Rotation${COLOR_RESET}"
pe "vault write -f ldap/rotate-role/service-account"
wait

# Read credentials after rotation
echo -e "${BLUE}### Step 11: Read Credentials After Manual Rotation${COLOR_RESET}"
pe "vault read ldap/static-cred/service-account"
wait

# Configure dynamic role
echo -e "${BLUE}### Step 12: Configure Dynamic Role${COLOR_RESET}"
echo "Dynamic roles create temporary users in LDAP"
pe "vault write ldap/role/dynamic-role \\
    creation_ldif=@creation.ldif \\
    deletion_ldif=@deletion.ldif \\
    rollback_ldif=@deletion.ldif \\
    default_ttl=\"1h\" \\
    max_ttl=\"24h\""
wait

# Generate dynamic credentials
echo -e "${BLUE}### Step 13: Generate Dynamic Credentials${COLOR_RESET}"
pe "vault read ldap/creds/dynamic-role"
wait

# Show another dynamic credential generation
echo -e "${BLUE}### Step 14: Generate Another Dynamic Credential${COLOR_RESET}"
pe "vault read ldap/creds/dynamic-role"
wait

# List active leases
echo -e "${BLUE}### Step 15: List Active Leases${COLOR_RESET}"
pe "vault list sys/leases/lookup/ldap/creds/dynamic-role"
wait

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗"
echo "║                     Demo Complete! 🎉                        ║"
echo "║                                                               ║"
echo "║  You've successfully demonstrated:                            ║"
echo "║  • LDAP integration with Vault                                ║"
echo "║  • Root credential rotation                                   ║"
echo "║  • Schedule-based rotation                                    ║"
echo "║  • Static role configuration and rotation                     ║"
echo "║  • Dynamic credential generation                              ║"
echo "╚═══════════════════════════════════════════════════════════════╝${COLOR_RESET}"
echo ""
