#!/bin/bash

# Reset script to restore vault-bind password for demo consistency

export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="myroot"

echo "🔄 Resetting vault-bind password for demo..."

# Reset vault-bind password in LDAP
docker exec openldap ldappasswd -s vaultbind123 -D "cn=admin,dc=demo,dc=hashicorp,dc=com" -w admin123 "cn=vault-bind,ou=people,dc=demo,dc=hashicorp,dc=com" 2>/dev/null

# Reset service-account password in LDAP  
docker exec openldap ldappasswd -s service123 -D "cn=admin,dc=demo,dc=hashicorp,dc=com" -w admin123 "cn=service-account,ou=people,dc=demo,dc=hashicorp,dc=com" 2>/dev/null

# Configure vault-bind user as the proper binding account
vault write ldap/config \
    binddn="cn=vault-bind,ou=people,dc=demo,dc=hashicorp,dc=com" \
    bindpass="vaultbind123" \
    url="ldap://openldap:389" \
    userdn="ou=people,dc=demo,dc=hashicorp,dc=com" 2>/dev/null

echo "✅ Demo environment reset and ready!"
