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
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                Step 1: Explore LDAP Directory Structure       ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${COLOR_RESET}"
echo "Before we configure Vault, let's see what users and data exist in our LDAP directory:"
echo ""
echo "🔍 Showing all users in the people organizational unit:"
pe "docker exec openldap ldapsearch -x -H ldap://localhost -b \"ou=people,dc=demo,dc=hashicorp,dc=com\" -D \"cn=admin,dc=demo,dc=hashicorp,dc=com\" -w admin123 \"(objectClass=person)\" cn dn"
echo ""
echo "📋 Notice we have several pre-configured users:"
echo "  • vault-bind: The service account Vault will use to connect to LDAP"
echo "  • static-account: A static account we'll manage with Vault" 
echo "  • dynamic-user: A template user for dynamic credential generation"
wait
clear

# Check Vault status
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                   Step 2: Verify Vault Status                 ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${COLOR_RESET}"
pe "vault status"
wait
clear

# Enable and show LDAP secrets engine
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                Step 3: Enable LDAP Secrets Engine             ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${COLOR_RESET}"
echo "First, let's enable the LDAP secrets engine if it's not already enabled"
pe "vault secrets list | grep ldap || vault secrets enable ldap"
wait
clear

# Configure LDAP integration
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                Step 4: Configure LDAP Integration             ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${COLOR_RESET}"
echo "This configures Vault to connect to our OpenLDAP server using a dedicated bind user"
pe "vault write ldap/config \\
    binddn=\"cn=vault-bind,ou=people,dc=demo,dc=hashicorp,dc=com\" \\
    bindpass=\"vaultbind123\" \\
    url=\"ldap://openldap:389\" \\
    userdn=\"ou=people,dc=demo,dc=hashicorp,dc=com\""
wait
clear

# Root credential rotation
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                 Step 5: Root Credential Rotation              ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${COLOR_RESET}"
echo "Root credential rotation requires the bind user to have LDAP search permissions"
echo "We have configured LDAP ACLs to allow vault-bind user to search and modify passwords"
echo "Let's verify our vault-bind configuration supports root rotation:"
pe "vault read ldap/config"
echo "Now rotate the root credentials using the properly configured vault-bind user:"
pe "vault write -f ldap/rotate-root"
wait
clear

# Verify root credential rotation
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              Step 6: Verify Root Credential Rotation          ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${COLOR_RESET}"
echo "Let's confirm the rotation succeeded by checking the updated timestamp:"
pe "vault read ldap/config | grep last_bind_password_rotation"
echo "Notice how the timestamp has been updated, proving the vault-bind user successfully rotated its own password!"
wait
clear

# Demonstrate password change
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              Step 7: Confirm Password Has Changed             ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${COLOR_RESET}"
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
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║          Step 8: Schedule-based Root Credential Rotation      ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${COLOR_RESET}"
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
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                 Step 9: Create Password Policy                ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${COLOR_RESET}"
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
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                 Step 10: Configure Static Role                ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${COLOR_RESET}"
echo "Using our properly configured vault-bind user for static role management"
echo "The vault-bind user has the necessary LDAP ACLs to manage service account passwords"
pe "vault write ldap/static-role/static-account dn=\"cn=static-account,ou=people,dc=demo,dc=hashicorp,dc=com\" username=\"static-account\" rotation_period=\"60s\""
wait
clear

# Read static role credentials
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              Step 11: Read Static Role Credentials            ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${COLOR_RESET}"
pe "vault read ldap/static-cred/static-account"
wait
clear

# Manual static role rotation
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              Step 12: Manual Static Role Rotation             ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${COLOR_RESET}"
pe "vault write -f ldap/rotate-role/static-account"
wait
clear

# Read credentials after rotation
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║          Step 13: Read Credentials After Manual Rotation      ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${COLOR_RESET}"
pe "vault read ldap/static-cred/static-account"
wait
clear

# Configure dynamic role
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                Step 14: Configure Dynamic Role                ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${COLOR_RESET}"
echo "Dynamic roles create temporary users in LDAP"
pe "vault write ldap/role/dynamic-role creation_ldif=@creation.ldif deletion_ldif=@deletion.ldif rollback_ldif=@deletion.ldif default_ttl=\"1h\" max_ttl=\"24h\""
wait
clear

# Generate dynamic credentials
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              Step 15: Generate Dynamic Credentials            ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${COLOR_RESET}"
pe "vault read ldap/creds/dynamic-role"
wait
clear

# Show another dynamic credential generation
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║           Step 16: Generate Another Dynamic Credential        ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${COLOR_RESET}"
pe "vault read ldap/creds/dynamic-role"
wait
clear

# Show dynamic users in LDAP
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              Step 17: Show Dynamic Users in LDAP              ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${COLOR_RESET}"
echo "Let's see the dynamic users that were created in our LDAP directory:"
echo "🔍 Searching for all dynamic users (v_token_*) in the people organizational unit:"
pe "docker exec openldap ldapsearch -x -H ldap://localhost -b \"ou=people,dc=demo,dc=hashicorp,dc=com\" -D \"cn=admin,dc=demo,dc=hashicorp,dc=com\" -w admin123 \"(cn=v_token_*)\" cn dn"
echo ""
echo "📋 Notice the dynamically created users:"
echo "  • Each user has a unique name starting with 'v_token_'"
echo "  • These are temporary users created by Vault's LDAP secrets engine"
echo "  • They will be automatically cleaned up when their lease expires"
wait
clear

# List active leases
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              Step 18: Inspect Active Lease Details            ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${COLOR_RESET}"
echo "Let's examine the active leases from our dynamic credentials generated earlier:"
echo ""
echo "📊 Checking which leases are still active (non-expired):"
pe "for lease in \$(vault list -format=json sys/leases/lookup/ldap/creds/dynamic-role | jq -r '.[]' 2>/dev/null); do TTL=\$(vault lease lookup \"ldap/creds/dynamic-role/\$lease\" | grep '^ttl' | awk '{print \$2}'); if [[ \"\$TTL\" != *\"-\"* ]]; then echo \"✅ Active lease: \$lease\"; vault lease lookup \"ldap/creds/dynamic-role/\$lease\" | grep -E 'ttl|expire_time'; echo; fi; done"
echo ""
echo "💡 Understanding the output:"
echo "  • Each lease represents one temporary LDAP user we created"
echo "  • TTL shows remaining time (positive = active, negative = expired)"
echo "  • expire_time shows when Vault will automatically delete the user"
echo "  • Active leases correspond to users still visible in LDAP"
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
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${COLOR_RESET}"
echo ""
