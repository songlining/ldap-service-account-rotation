#!/bin/bash

# HashiCorp Vault LDAP Demo Initialization Script
# This script sets up Vault and LDAP for the demo

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Vault configuration
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="myroot"

echo -e "${BLUE}🚀 HashiCorp Vault LDAP Demo Setup${NC}"
echo "=================================="

# Wait for Vault to be ready
echo -e "${YELLOW}⏳ Waiting for Vault to be ready...${NC}"
until vault status &>/dev/null; do
    echo "Waiting for Vault..."
    sleep 2
done

echo -e "${GREEN}✅ Vault is ready!${NC}"
vault status

# Enable LDAP secrets engine
echo -e "${YELLOW}🔧 Enabling LDAP secrets engine...${NC}"
vault secrets enable ldap

# Wait for OpenLDAP to be ready
echo -e "${YELLOW}⏳ Waiting for OpenLDAP to be ready...${NC}"
sleep 10

# Create LDAP bind user and test users in OpenLDAP
echo -e "${YELLOW}👥 Setting up LDAP users...${NC}"
docker exec openldap ldapadd -x -D "cn=admin,dc=demo,dc=hashicorp,dc=com" -w admin123 << EOF
dn: ou=people,dc=demo,dc=hashicorp,dc=com
objectClass: organizationalUnit
ou: people

dn: ou=groups,dc=demo,dc=hashicorp,dc=com
objectClass: organizationalUnit
ou: groups

dn: cn=vault-bind,ou=people,dc=demo,dc=hashicorp,dc=com
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
objectClass: simpleSecurityObject
cn: vault-bind
sn: vault-bind
userPassword: vaultbind123
uid: vault-bind

dn: cn=service-account,ou=people,dc=demo,dc=hashicorp,dc=com
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
cn: service-account
sn: service-account
userPassword: service123
uid: service-account

dn: cn=dynamic-user,ou=people,dc=demo,dc=hashicorp,dc=com
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
cn: dynamic-user
sn: dynamic-user
userPassword: dynamic123
uid: dynamic-user
EOF

# Set proper passwords using ldappasswd for better password hashing
echo -e "${YELLOW}🔐 Setting secure passwords...${NC}"
docker exec openldap ldappasswd -s vaultbind123 -D "cn=admin,dc=demo,dc=hashicorp,dc=com" -w admin123 "cn=vault-bind,ou=people,dc=demo,dc=hashicorp,dc=com"
docker exec openldap ldappasswd -s service123 -D "cn=admin,dc=demo,dc=hashicorp,dc=com" -w admin123 "cn=service-account,ou=people,dc=demo,dc=hashicorp,dc=com"
docker exec openldap ldappasswd -s dynamic123 -D "cn=admin,dc=demo,dc=hashicorp,dc=com" -w admin123 "cn=dynamic-user,ou=people,dc=demo,dc=hashicorp,dc=com"

echo -e "${GREEN}✅ LDAP users created successfully!${NC}"

# Configure LDAP ACLs to give vault-bind user search permissions
echo -e "${YELLOW}🔐 Configuring LDAP ACLs for vault-bind user...${NC}"
docker cp ldap-acl.ldif openldap:/tmp/ldap-acl.ldif
docker exec openldap ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/ldap-acl.ldif

echo -e "${GREEN}✅ LDAP ACLs configured successfully!${NC}"

# Configure Vault LDAP secrets engine 
echo -e "${YELLOW}🔧 Configuring Vault LDAP integration...${NC}"

# First configure with admin for initial setup
vault write ldap/config \
    binddn="cn=admin,dc=demo,dc=hashicorp,dc=com" \
    bindpass="admin123" \
    url="ldap://openldap:389" \
    userdn="ou=people,dc=demo,dc=hashicorp,dc=com"

# Now switch to vault-bind user with proper ACLs
echo -e "${YELLOW}🔄 Switching to vault-bind user...${NC}"
vault write ldap/config \
    binddn="cn=vault-bind,ou=people,dc=demo,dc=hashicorp,dc=com" \
    bindpass="vaultbind123" \
    url="ldap://openldap:389" \
    userdn="ou=people,dc=demo,dc=hashicorp,dc=com"

echo -e "${GREEN}✅ Vault LDAP configuration complete!${NC}"

# Test the configuration
echo -e "${YELLOW}🧪 Testing LDAP configuration...${NC}"
vault read ldap/config

echo -e "${GREEN}🎉 Setup complete!${NC}"
echo ""
echo -e "${YELLOW}💡 You can now run the demo script: ./demo.sh${NC}"
echo ""
echo -e "${BLUE}Demo Information:${NC}"
echo "=================="
echo -e "Vault URL: ${GREEN}http://localhost:8200${NC}"
echo -e "Vault Root Token: ${GREEN}myroot${NC}"
echo -e "LDAP Admin: ${GREEN}cn=admin,dc=demo,dc=hashicorp,dc=com${NC}"
echo -e "LDAP Admin Password: ${GREEN}admin123${NC}"
echo -e "Vault Bind User: ${GREEN}cn=vault-bind,ou=people,dc=demo,dc=hashicorp,dc=com${NC}"
echo -e "Vault Bind Password: ${GREEN}vaultbind123${NC}"