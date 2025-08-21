#!/bin/bash

# Quick verification script to test the demo environment

export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="myroot"

echo "🔍 Verifying HashiCorp Vault LDAP Demo Environment"
echo "=================================================="

# Check if Docker containers are running
echo ""
echo "📦 Docker Container Status:"
docker-compose ps

# Check Vault status
echo ""
echo "🏛️  Vault Status:"
if vault status 2>/dev/null; then
    echo "✅ Vault is running and accessible"
else
    echo "❌ Vault is not accessible"
    exit 1
fi

# Check LDAP secrets engine
echo ""
echo "🔐 LDAP Secrets Engine:"
if vault secrets list | grep -q ldap; then
    echo "✅ LDAP secrets engine is enabled"
else
    echo "❌ LDAP secrets engine is not enabled"
fi

# Check LDAP configuration
echo ""
echo "⚙️  LDAP Configuration:"
if vault read ldap/config 2>/dev/null | grep -q "binddn"; then
    echo "✅ LDAP is configured"
else
    echo "❌ LDAP is not configured"
fi

# Test LDAP connection
echo ""
echo "🔗 LDAP Connection Test:"
if docker exec openldap ldapsearch -x -H ldap://localhost -b "dc=demo,dc=hashicorp,dc=com" -s base 2>/dev/null | grep -q "dc=demo"; then
    echo "✅ OpenLDAP is accessible"
else
    echo "❌ OpenLDAP is not accessible"
fi

# Check if static role exists
echo ""
echo "👤 Static Role Status:"
if vault list ldap/static-role 2>/dev/null | grep -q "static-account"; then
    echo "✅ Static role 'static-account' exists"
else
    echo "⚠️  Static role 'static-account' not found (may not be configured yet)"
fi

# Check if dynamic role exists
echo ""
echo "🆔 Dynamic Role Status:"
if vault list ldap/role 2>/dev/null | grep -q "dynamic-role"; then
    echo "✅ Dynamic role 'dynamic-role' exists"
else
    echo "⚠️  Dynamic role 'dynamic-role' not found (may not be configured yet)"
fi

echo ""
echo "🎯 Environment verification complete!"
echo ""
echo "If all checks pass, you can run the demo with: ./demo.sh"
