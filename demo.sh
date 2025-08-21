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
TYPE_SPEED=100
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
clear

# Show LDAP directory structure
echo -e "${BLUE}### Step 1: Explore LDAP Directory Structure${COLOR_RESET}"
echo "Before we configure Vault, let's see what users and data exist in our LDAP directory:"
echo ""
echo "🔍 Showing all users in the people organizational unit:"
pe "docker exec openldap ldapsearch -x -H ldap://localhost -b \"ou=people,dc=demo,dc=hashicorp,dc=com\" -D \"cn=admin,dc=demo,dc=hashicorp,dc=com\" -w admin123 \"(objectClass=person)\" cn dn"
echo ""
echo "📋 Notice we have several pre-configured users:"
echo "  • vault-bind: The service account Vault will use to connect to LDAP"
echo "  • service-account: A static account we'll manage with Vault" 
echo "  • dynamic-user: A template user for dynamic credential generation"
wait
clear

# Check Vault status
echo -e "${BLUE}### Step 2: Verify Vault Status${COLOR_RESET}"
pe "vault status"
wait
clear

# Enable and show LDAP secrets engine
echo -e "${BLUE}### Step 3: Enable LDAP Secrets Engine${COLOR_RESET}"
echo "First, let's enable the LDAP secrets engine if it's not already enabled"
pe "vault secrets list | grep ldap || vault secrets enable ldap"
wait
clear

# Configure LDAP integration
echo -e "${BLUE}### Step 4: Configure LDAP Integration${COLOR_RESET}"
echo "This configures Vault to connect to our OpenLDAP server using a dedicated bind user"
pe "vault write ldap/config \\
    binddn=\"cn=vault-bind,ou=people,dc=demo,dc=hashicorp,dc=com\" \\
    bindpass=\"vaultbind123\" \\
    url=\"ldap://openldap:389\" \\
    userdn=\"ou=people,dc=demo,dc=hashicorp,dc=com\""
wait
clear

# Root credential rotation
echo -e "${BLUE}### Step 5: Root Credential Rotation${COLOR_RESET}"
echo "Root credential rotation requires the bind user to have LDAP search permissions"
echo "We have configured LDAP ACLs to allow vault-bind user to search and modify passwords"
echo "Let's verify our vault-bind configuration supports root rotation:"
pe "vault read ldap/config"
echo "Now rotate the root credentials using the properly configured vault-bind user:"
pe "vault write -f ldap/rotate-root"
wait
clear

# Verify root credential rotation
echo -e "${BLUE}### Step 6: Verify Root Credential Rotation${COLOR_RESET}"
echo "Let's confirm the rotation succeeded by checking the updated timestamp:"
pe "vault read ldap/config | grep last_bind_password_rotation"
echo "Notice how the timestamp has been updated, proving the vault-bind user successfully rotated its own password!"
wait
clear

# Demonstrate password change
echo -e "${BLUE}### Step 7: Confirm Password Has Changed${COLOR_RESET}"
echo "Let's verify the vault-bind password has actually changed by testing the old password:"
echo "Testing old password 'vaultbind123' (this should fail with 'Invalid credentials'):"
pe "docker exec openldap ldapwhoami -x -D \"cn=vault-bind,ou=people,dc=demo,dc=hashicorp,dc=com\" -w vaultbind123"
echo ""
echo "✅ As expected, LDAP returned 'Invalid credentials (49)' - confirming the password has changed!"
echo "Note: Vault manages the new password internally for security - it's not exposed to users."
echo "This demonstrates that root credential rotation successfully changed the bind user's password."
wait
clear

# Schedule-based root credential rotation
echo -e "${BLUE}### Step 8: Schedule-based Root Credential Rotation${COLOR_RESET}"
echo "Configure automatic rotation every 24 hours with a password policy"
echo "Note: This sets the bind account to rotate automatically using the demo-policy"
pe "vault write ldap/config \\
    binddn=\"cn=vault-bind,ou=people,dc=demo,dc=hashicorp,dc=com\" \\
    url=\"ldap://openldap:389\" \\
    userdn=\"ou=people,dc=demo,dc=hashicorp,dc=com\" \\
    password_policy=\"demo-policy\" \\
    rotate_period=\"24h\""
wait
clear

# Create password policy
echo -e "${BLUE}### Step 9: Create Password Policy${COLOR_RESET}"
echo "Let's first examine the password policy we'll be applying:"
pe "cat password-policy.hcl"
echo ""
echo "This policy ensures generated passwords have:"
echo "  • Minimum 20 characters length"
echo "  • At least 1 lowercase letter (a-z)"
echo "  • At least 1 uppercase letter (A-Z)"
echo "  • At least 1 number (0-9)"
echo "  • At least 1 special character (!@#$%^&*)"
echo ""
echo "Now let's create this password policy in Vault:"
pe "vault write sys/policies/password/demo-policy policy=@password-policy.hcl"
wait
clear

# Configure static role
echo -e "${BLUE}### Step 10: Configure Static Role${COLOR_RESET}"
echo "Using our properly configured vault-bind user for static role management"
echo "The vault-bind user has the necessary LDAP ACLs to manage service account passwords"
pe "vault write ldap/static-role/service-account dn=\"cn=service-account,ou=people,dc=demo,dc=hashicorp,dc=com\" username=\"service-account\" rotation_period=\"60s\""
wait
clear

# Read static role credentials
echo -e "${BLUE}### Step 11: Read Static Role Credentials${COLOR_RESET}"
pe "vault read ldap/static-cred/service-account"
wait
clear

# Manual static role rotation
echo -e "${BLUE}### Step 12: Manual Static Role Rotation${COLOR_RESET}"
pe "vault write -f ldap/rotate-role/service-account"
wait
clear

# Read credentials after rotation
echo -e "${BLUE}### Step 13: Read Credentials After Manual Rotation${COLOR_RESET}"
pe "vault read ldap/static-cred/service-account"
wait
clear

# Configure dynamic role
echo -e "${BLUE}### Step 14: Configure Dynamic Role${COLOR_RESET}"
echo "Dynamic roles create temporary users in LDAP"
pe "vault write ldap/role/dynamic-role creation_ldif=@creation.ldif deletion_ldif=@deletion.ldif rollback_ldif=@deletion.ldif default_ttl=\"1h\" max_ttl=\"24h\""
wait
clear

# Generate dynamic credentials
echo -e "${BLUE}### Step 15: Generate Dynamic Credentials${COLOR_RESET}"
pe "vault read ldap/creds/dynamic-role"
wait
clear

# Show another dynamic credential generation
echo -e "${BLUE}### Step 16: Generate Another Dynamic Credential${COLOR_RESET}"
pe "vault read ldap/creds/dynamic-role"
wait
clear

# List active leases
echo -e "${BLUE}### Step 17: List Active Leases${COLOR_RESET}"
pe "vault list sys/leases/lookup/ldap/creds/dynamic-role"
wait
clear

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗"
echo "║                     Demo Complete! 🎉                         ║"
echo "║                                                               ║"
echo "║  You've successfully demonstrated:                            ║"
echo "║  • LDAP integration with Vault                                ║"
echo "║  • Root credential rotation                                   ║"
echo "║  • Schedule-based rotation                                    ║"
echo "║  • Static role configuration and rotation                     ║"
echo "║  • Dynamic credential generation                              ║"
echo "╚═══════════════════════════════════════════════════════════════╝${COLOR_RESET}"
echo ""
