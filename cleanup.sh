#!/bin/bash

# Cleanup script for the demo environment

echo "🧹 Cleaning up HashiCorp Vault LDAP Demo..."

# Stop and remove containers
echo "Stopping Docker containers..."
docker-compose down -v

# Remove demo-magic.sh if downloaded
if [ -f "demo-magic.sh" ]; then
    echo "Removing demo-magic.sh..."
    rm -f demo-magic.sh
fi

# Remove any temporary files
echo "Cleaning up temporary files..."
rm -f .vault-token

echo "✅ Cleanup complete!"
echo "To restart the demo, run: docker-compose up -d && ./vault-init.sh"
