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

## 📁 Project Structure

```
├── docker-compose.yml      # Container orchestration
├── vault-init.sh          # Vault and LDAP initialization
├── demo.sh                # Interactive demo script
├── password-policy.hcl     # Vault password policy
├── users.ldif             # LDAP users definition
├── verify.sh              # Environment verification
├── cleanup.sh             # Cleanup script
├── Makefile               # Convenient commands
├── .env                   # Environment variables
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
| **service-account** | `cn=service-account,ou=people,dc=demo,dc=hashicorp,dc=com` | Static role demo |
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

1. **Vault Status Verification** - Confirm Vault is running
2. **LDAP Secrets Engine** - Show enabled LDAP engine
3. **LDAP Integration** - Configure Vault to connect to OpenLDAP
4. **Configuration Verification** - Verify LDAP settings
5. **Root Credential Rotation** - Rotate bind account password
6. **Schedule-based Rotation** - Configure automatic rotation with password policy
7. **Password Policy Creation** - Define password complexity rules
8. **Static Role Configuration** - Create managed service account
9. **Static Credential Reading** - Retrieve current password
10. **Manual Static Rotation** - Trigger immediate rotation
11. **Post-rotation Verification** - Confirm new password
12. **Dynamic Role Configuration** - Create temporary user template
13. **Dynamic Credential Generation** - Create temporary users
14. **Multiple Dynamic Users** - Show multiple user creation
15. **Lease Management** - Display active credential leases

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
vault read ldap/static-cred/service-account

# Rotate static role manually
vault write -f ldap/rotate-role/service-account

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
  -D "cn=service-account,ou=people,dc=demo,dc=hashicorp,dc=com" \
  -w <current_password>

# Check user details
docker exec openldap ldapsearch -x -H ldap://localhost \
  -b "ou=people,dc=demo,dc=hashicorp,dc=com" \
  -D "cn=admin,dc=demo,dc=hashicorp,dc=com" -w admin123
```

## 📊 Available Make Commands

```bash
make help          # Show all available commands
make start          # Start Docker containers
make stop           # Stop Docker containers  
make init           # Initialize Vault and LDAP
make demo           # Run interactive demo
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
