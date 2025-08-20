#!/bin/bash

# Reset script to restore demo environment to clean state

export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="myroot"

echo "🔄 Resetting demo environment..."

# Reset vault-bind password in LDAP
echo "  📝 Resetting vault-bind password..."
docker exec openldap ldappasswd -s vaultbind123 -D "cn=admin,dc=demo,dc=hashicorp,dc=com" -w admin123 "cn=vault-bind,ou=people,dc=demo,dc=hashicorp,dc=com" 2>/dev/null

# Reset service-account password in LDAP  
echo "  📝 Resetting service-account password..."
docker exec openldap ldappasswd -s service123 -D "cn=admin,dc=demo,dc=hashicorp,dc=com" -w admin123 "cn=service-account,ou=people,dc=demo,dc=hashicorp,dc=com" 2>/dev/null

# Clean up any dynamic users that might be left behind
echo "  🧹 Cleaning up dynamic users..."
docker exec openldap ldapsearch -x -H ldap://localhost -b "ou=people,dc=demo,dc=hashicorp,dc=com" -D "cn=admin,dc=demo,dc=hashicorp,dc=com" -w admin123 "(cn=v_token_*)" dn 2>/dev/null | grep "^dn:" | while read line; do
    user_dn=$(echo $line | cut -d' ' -f2-)
    if [[ "$user_dn" == *"v_token_"* ]]; then
        echo "    🗑️  Removing dynamic user: $user_dn"
        docker exec openldap ldapdelete -D "cn=admin,dc=demo,dc=hashicorp,dc=com" -w admin123 "$user_dn" 2>/dev/null
    fi
done

# Revoke any active dynamic credential leases
echo "  🔓 Revoking active leases..."
vault list sys/leases/lookup/ldap/creds/dynamic-role 2>/dev/null | tail -n +3 | while read lease; do
    if [[ ! -z "$lease" && "$lease" != "Keys" && "$lease" != "----" ]]; then
        echo "    🔓 Revoking lease: $lease"
        vault lease revoke "ldap/creds/dynamic-role/$lease" 2>/dev/null
    fi
done

# Delete and recreate Vault configurations to ensure clean state
echo "  🔧 Resetting Vault configurations..."

# Remove existing roles and policies
vault delete ldap/static-role/service-account 2>/dev/null
vault delete ldap/role/dynamic-role 2>/dev/null
vault delete sys/policies/password/demo-policy 2>/dev/null

# Reconfigure LDAP with vault-bind user
echo "  🔗 Reconfiguring LDAP integration..."
vault write ldap/config \
    binddn="cn=vault-bind,ou=people,dc=demo,dc=hashicorp,dc=com" \
    bindpass="vaultbind123" \
    url="ldap://openldap:389" \
    userdn="ou=people,dc=demo,dc=hashicorp,dc=com" 2>/dev/null

echo "✅ Demo environment reset and ready!"
echo ""
echo "🎭 You can now run 'make demo' for a clean demonstration."
