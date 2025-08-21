# HashiCorp Vault LDAP Service Account Rotation Demo

This demo showcases HashiCorp Vault's LDAP secrets engine capabilities for service account rotation using Docker Compose on macOS.

## 🎯 Overview

This demonstration illustrates how to use HashiCorp Vault Enterprise to manage LDAP service account passwords through:
- **Root credential rotation** - Rotating the bind account Vault uses to connect to LDAP
- **Schedule-based rotation** - Automatic rotation on a time schedule
- **Static roles** - Managing existing LDAP users with Vault-controlled password rotation
- **Dynamic roles** - Creating temporary LDAP users on-demand with automatic cleanup

## 📋 Prerequisites

- **macOS** (tested environment)
- **Docker Desktop** installed and running
- **HashiCorp Vault license file** (`vault.hclic`) in the project directory
- **Terminal** with `curl` and `make` commands available

## 🚀 Quick Start

### 1. Complete Setup (Recommended)
```bash
# Start everything with one command
make setup
```

### 2. Manual Setup
```bash
# Start Docker containers
make start

# Initialize Vault and LDAP
make init
```

### 3. Run the Demo
```bash
# Run the interactive demo
make demo
```

### 4. Verify Environment
```bash
# Check if everything is working
make verify
```

### 5. Reset Environment (Before Running Demo Again)
```bash
# Reset environment for clean demo runs
make reset
```

The reset command:
- Restores original LDAP user passwords
- Cleans up dynamic users from LDAP
- Revokes all active credential leases
- Resets Vault LDAP configuration

## 📁 Project Structure

```
├── docker-compose.yml      # Container orchestration
├── vault-init.sh          # Vault and LDAP initialization
├── demo.sh                # Interactive demo script
├── reset-demo.sh          # Reset environment script
├── password-policy.hcl     # Vault password policy
├── users.ldif             # LDAP users definition
├── creation.ldif          # Dynamic user creation template
├── deletion.ldif          # Dynamic user deletion template
├── verify.sh              # Environment verification
├── cleanup.sh             # Cleanup script
├── Makefile               # Convenient commands
└── README.md              # This file
```

## 🏗️ Architecture

```
┌─────────────────┐     ┌─────────────────┐
│   Vault         │────▶│   OpenLDAP      │
│   Enterprise    │     │   Server        │
│   (Port 8200)   │     │   (Port 389)    │
└─────────────────┘     └─────────────────┘
        │                        │
        └────────────────────────┘
           Docker Network (vault-ldap)
```

## 🛠️ Services

### HashiCorp Vault Enterprise
- **Image**: `hashicorp/vault-enterprise:latest-ent`
- **Port**: 8200
- **Features**: LDAP secrets engine, password policies, role management
- **License**: Uses your `vault.hclic` file

### OpenLDAP
- **Image**: `osixia/openldap:1.5.0`
- **Port**: 389 (LDAP), 636 (LDAPS)
- **Domain**: `demo.hashicorp.com`
- **Base DN**: `dc=demo,dc=hashicorp,dc=com`

## 👥 Pre-configured LDAP Users

| User | DN | Purpose |
|------|----|---------| 
| **admin** | `cn=admin,dc=demo,dc=hashicorp,dc=com` | LDAP administrator (setup only) |
| **vault-bind** | `cn=vault-bind,ou=people,dc=demo,dc=hashicorp,dc=com` | Vault binding account with ACLs |
| **static-account** | `cn=static-account,ou=people,dc=demo,dc=hashicorp,dc=com` | Static role demo |
| **dynamic-user** | `cn=dynamic-user,ou=people,dc=demo,dc=hashicorp,dc=com` | Template for dynamic roles |

### 🔐 LDAP Security Configuration

The demo properly configures LDAP ACLs to allow the **vault-bind** user to:
- Search the LDAP directory tree
- Read user attributes  
- Modify userPassword attributes for service accounts
- Rotate its own password (root credential rotation)

This follows security best practices by using a **dedicated service account** with **minimal required permissions** instead of the admin account.

## 🎭 Demo Flow

The interactive demo (`./demo.sh`) demonstrates:

1. **Explore LDAP Directory Structure** - Show existing users in LDAP
2. **Verify Vault Status** - Confirm Vault is running and accessible
3. **Enable LDAP Secrets Engine** - Configure LDAP secrets engine
4. **Configure LDAP Integration** - Connect Vault to OpenLDAP server
5. **Root Credential Rotation** - Rotate bind account password
6. **Verify Root Credential Rotation** - Confirm rotation succeeded
7. **Confirm Password Has Changed** - Test old password fails
8. **Schedule-based Root Credential Rotation** - Configure automatic rotation
9. **Create Password Policy** - Define password complexity rules
10. **Configure Static Role** - Create managed service account
11. **Read Static Role Credentials** - Retrieve current password
12. **Manual Static Role Rotation** - Trigger immediate rotation
13. **Read Credentials After Manual Rotation** - Confirm new password
14. **Configure Dynamic Role** - Create temporary user template
15. **Generate Dynamic Credentials** - Create temporary users
16. **Generate Another Dynamic Credential** - Show multiple user creation
17. **Show Dynamic Users in LDAP** - Display created users in LDAP directory
18. **Inspect Active Lease Details** - Examine non-expired credential leases

## 🔧 Manual Commands

After setup, you can manually interact with the services:

### Vault Operations
```bash
# Set environment variables
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="myroot"

# Check LDAP configuration
vault read ldap/config

# List static roles
vault list ldap/static-role

# Read static role credentials
vault read ldap/static-cred/static-account

# Rotate static role manually
vault write -f ldap/rotate-role/static-account

# Generate dynamic credentials
vault read ldap/creds/dynamic-role

# List active leases
vault list sys/leases/lookup/ldap/creds/dynamic-role
```

### LDAP Operations
```bash
# Search LDAP directory
docker exec openldap ldapsearch -x -H ldap://localhost \
  -b "dc=demo,dc=hashicorp,dc=com" \
  -D "cn=admin,dc=demo,dc=hashicorp,dc=com" -w admin123

# Test user authentication
docker exec openldap ldapwhoami -x \
  -D "cn=static-account,ou=people,dc=demo,dc=hashicorp,dc=com" \
  -w <current_password>

# Check user details
docker exec openldap ldapsearch -x -H ldap://localhost \
  -b "ou=people,dc=demo,dc=hashicorp,dc=com" \
  -D "cn=admin,dc=demo,dc=hashicorp,dc=com" -w admin123

# Search for dynamic users created by Vault
docker exec openldap ldapsearch -x -H ldap://localhost \
  -b "ou=people,dc=demo,dc=hashicorp,dc=com" \
  -D "cn=admin,dc=demo,dc=hashicorp,dc=com" -w admin123 \
  "(cn=v_token_*)" cn dn
```

## 📊 Available Make Commands

```bash
make help          # Show all available commands
make start          # Start Docker containers
make stop           # Stop Docker containers  
make init           # Initialize Vault and LDAP
make demo           # Run interactive demo
make reset          # Reset environment for clean demo runs
make verify         # Verify environment
make clean          # Clean up everything
make setup          # Complete setup (start + init)
make status         # Show service status
```

## 🔐 Default Credentials

### Vault
- **URL**: http://localhost:8200
- **Root Token**: `myroot`

### LDAP
- **Admin User**: `cn=admin,dc=demo,dc=hashicorp,dc=com`
- **Admin Password**: `admin123`
- **Bind User**: `cn=vault-bind,ou=people,dc=demo,dc=hashicorp,dc=com` (used by Vault)
- **Bind Password**: `vaultbind123`

## 🔍 Troubleshooting

### Docker Not Running
```bash
# Start Docker Desktop manually or via command
open -a Docker
```

### Vault Not Ready
```bash
# Check Vault status
vault status

# Check Vault logs
docker logs vault-enterprise
```

### LDAP Connection Issues
```bash
# Check OpenLDAP logs
docker logs openldap

# Test LDAP connectivity
docker exec openldap ldapsearch -x -H ldap://localhost \
  -b "dc=demo,dc=hashicorp,dc=com"
```

### Reset Everything
```bash
# Complete cleanup and restart
make clean
make setup
```

### Common Issues

1. **"Docker daemon not running"** - Start Docker Desktop
2. **"Vault not accessible"** - Wait for Vault to fully start (30-60 seconds)
3. **"LDAP bind failed"** - Check if OpenLDAP container is healthy
4. **"Demo script hangs"** - Press Enter to continue through demo steps

## 🧹 Cleanup

### Stop Services
```bash
make stop
```

### Complete Cleanup
```bash
make clean
# This removes containers, volumes, and temporary files
```

### Manual Cleanup
```bash
# Stop and remove everything
docker-compose down -v

# Remove downloaded demo-magic.sh
rm -f demo-magic.sh

# Remove temporary files
rm -f .vault-token
```

## 🔄 Workflow Examples

### Development Workflow
```bash
# Start environment
make setup

# Run demo
make demo

# Make changes to scripts
# ... edit files ...

# Test changes
make verify

# Clean up when done
make clean
```

### Demo Presentation Workflow
```bash
# Setup before presentation
make setup

# Verify everything works
make verify

# Run the demo presentation
make demo
# (Use spacebar or Enter to advance through steps)

# Reset for another demo
docker-compose restart
./vault-init.sh
```

## 📝 Notes

- The demo uses **development mode** for Vault (not for production!)
- All data is stored in Docker volumes and will persist between container restarts
- The environment is designed for **demonstration purposes only**
- LDAP uses **unencrypted connections** for simplicity
- Passwords and tokens are **hardcoded for demo purposes**

## 🆘 Support

For issues with this demo:
1. Check the troubleshooting section above
2. Verify all prerequisites are met
3. Review Docker and Vault logs
4. Try a complete cleanup and restart

For HashiCorp Vault questions:
- [Vault Documentation](https://www.vaultproject.io/docs)
- [LDAP Secrets Engine Guide](https://developer.hashicorp.com/vault/docs/secrets/ldap)

---

**⚠️ Important**: This demo environment is for educational and demonstration purposes only. Do not use these configurations in production environments.
