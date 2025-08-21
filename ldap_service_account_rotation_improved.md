# HashiCorp Vault LDAP Service Account Rotation Demo

## 🎯 Project Objectives
Create a comprehensive command-line demo showcasing HashiCorp Vault's LDAP secrets engine capabilities for service account rotation. This demo should be:
- **Professional**: Suitable for customer presentations and training
- **Educational**: Clear explanations of each step and concept
- **Repeatable**: Easy to reset and run multiple times
- **Production-like**: Following security best practices

## 🏗️ Architecture Requirements

### Platform & Environment
- **Target Platform**: macOS (local development/demo machine)
- **Deployment**: Docker Compose for easy setup and teardown
- **Interface**: Command-line based with visual formatting
- **Demo Tool**: `demo-magic.sh` for paced, interactive presentations

### Infrastructure Components

#### HashiCorp Vault Enterprise
- **Image**: `hashicorp/vault-enterprise:latest-ent`
- **Port**: 8200 (HTTP for demo simplicity)
- **License**: Use `vault.hclic` file from project directory
- **Configuration**: Development mode with persistent storage
- **Security**: Pre-configured with root token for demo ease
- **Validation**: `vault status` command should show "Sealed: false"

#### OpenLDAP Server
- **Image**: `osixia/openldap:1.5.0` 
- **Ports**: 389 (LDAP), 636 (LDAPS - optional)
- **Domain**: `demo.hashicorp.com`
- **Base DN**: `dc=demo,dc=hashicorp,dc=com`
- **Admin Credentials**: `cn=admin,dc=demo,dc=hashicorp,dc=com` / `admin123`

#### Network Configuration
- **Docker Network**: Custom network for service communication
- **Service Discovery**: Services communicate by container name
- **Security**: LDAP ACLs configured for proper access control

## 📁 Required Project Structure

```
ldap-service-account-rotation/
├── docker-compose.yml           # Service orchestration
├── Makefile                     # Convenient commands with help
├── README.md                    # Comprehensive documentation
├── demo.sh                      # Main interactive demo script
├── reset-demo.sh               # Environment reset script
├── vault-init.sh               # Vault and LDAP initialization
├── verify.sh                   # Environment validation
├── cleanup.sh                  # Complete cleanup script
├── password-policy.hcl         # Vault password policy definition
├── users.ldif                  # LDAP user definitions
├── creation.ldif              # Dynamic user creation template
├── deletion.ldif              # Dynamic user deletion template
├── ldap-acl.ldif             # LDAP access control configuration
└── vault.hclic               # Vault Enterprise license
```

## 👥 LDAP User Configuration

### Pre-configured Users
| User | DN | Purpose | Password |
|------|----|---------| ---------|
| **admin** | `cn=admin,dc=demo,dc=hashicorp,dc=com` | LDAP administrator | `admin123` |
| **vault-bind** | `cn=vault-bind,ou=people,dc=demo,dc=hashicorp,dc=com` | Vault service account | `vaultbind123` |
| **static-account** | `cn=static-account,ou=people,dc=demo,dc=hashicorp,dc=com` | Static role demo target | `static123` |
| **dynamic-user** | `cn=dynamic-user,ou=people,dc=demo,dc=hashicorp,dc=com` | Template for dynamic users | `dynamic123` |

### LDAP Security Configuration
- **vault-bind** user must have ACLs to:
  - Search the directory tree
  - Read user attributes
  - Modify userPassword for service accounts
  - Change its own password (for root rotation)
- Use **minimal required permissions** following security best practices
- **No admin account usage** by Vault in production-like setup

## 🎭 Detailed Demo Flow

Each step should be presented in a **professional box format** with clear explanations:

### Phase 1: Environment Setup & Verification
1. **Explore LDAP Directory Structure**
   - Show existing users and organizational structure
   - Explain the purpose of each pre-configured user
   - **Expected Output**: Clean LDAP directory listing

2. **Verify Vault Status** 
   - Confirm Vault is unsealed and accessible
   - Display server version and status
   - **Expected Output**: "Sealed: false, Version: X.X.X"

3. **Enable LDAP Secrets Engine**
   - Show secrets engine listing before/after
   - **Expected Output**: LDAP engine in enabled state

### Phase 2: Integration Configuration
4. **Configure LDAP Integration**
   - Use vault-bind service account (not admin)
   - Show configuration parameters
   - **Expected Output**: Successful configuration confirmation

5. **Root Credential Rotation**
   - Demonstrate Vault rotating its own bind password
   - **Expected Output**: Updated timestamp in configuration

6. **Verify Root Credential Rotation**
   - Show timestamp change in configuration
   - **Expected Output**: Recent rotation timestamp

7. **Confirm Password Has Changed**
   - Test old password fails authentication
   - **Expected Output**: LDAP "Invalid credentials" error

### Phase 3: Automated Rotation Setup
8. **Schedule-based Root Credential Rotation**
   - Configure automatic 24-hour rotation
   - Link to password policy
   - **Expected Output**: Updated configuration with schedule

9. **Create Password Policy**
   - Show password complexity requirements
   - Explain security benefits
   - **Expected Output**: Policy creation confirmation

### Phase 4: Static Role Management
10. **Configure Static Role**
    - Create role for existing service account
    - Set rotation period
    - **Expected Output**: Role configuration success

11. **Read Static Role Credentials**
    - Retrieve current managed password
    - **Expected Output**: Username and current password

12. **Manual Static Role Rotation**
    - Trigger immediate password change
    - **Expected Output**: Rotation success message

13. **Read Credentials After Manual Rotation**
    - Show new password differs from previous
    - **Expected Output**: Updated password value

### Phase 5: Dynamic Credential Management
14. **Configure Dynamic Role**
    - Set up temporary user creation template
    - Define TTL and cleanup behavior
    - **Expected Output**: Dynamic role configuration

15. **Generate Dynamic Credentials**
    - Create first temporary user
    - **Expected Output**: Username, password, lease ID

16. **Generate Another Dynamic Credential**
    - Create second temporary user to show uniqueness
    - **Expected Output**: Different username, new lease ID

17. **Show Dynamic Users in LDAP**
    - Query LDAP to display created users (v_token_*)
    - **Expected Output**: List of temporary users in directory

18. **Inspect Active Lease Details**
    - Show only non-expired leases with TTL information
    - Explain lease lifecycle and cleanup
    - **Expected Output**: Active lease details with positive TTL

## 🎨 User Experience Requirements

### Visual Presentation
- **Step Headers**: Professional box formatting (╔══╗ style)
- **Colors**: Blue headers, green success, yellow warnings
- **Icons**: Emojis for visual appeal (🔍, 📋, ✅, etc.)
- **Pacing**: Use `demo-magic.sh` `pe` command for each Vault operation

### Error Handling
- **Graceful Failures**: Handle service startup delays
- **Clear Messages**: Explain what went wrong and how to fix
- **Recovery Options**: Suggest remediation steps

### Reset Functionality
- **Complete Reset**: `make reset` command that:
  - Restores original LDAP passwords
  - Removes all dynamic users from LDAP
  - Revokes all active credential leases
  - Resets Vault LDAP configuration
  - Prepares for clean demo re-run

## 🔧 Operational Requirements

### Make Commands (with help text)
```bash
make help          # Show all available commands
make start         # Start Docker containers
make stop          # Stop Docker containers
make init          # Initialize Vault and LDAP
make demo          # Run interactive demo
make reset         # Reset environment for clean runs
make verify        # Verify environment health
make clean         # Complete cleanup (containers, volumes)
make setup         # Complete setup (start + init)
make status        # Show service status
```

### Verification Commands
- Health checks for all services
- LDAP connectivity testing
- Vault unsealed status validation
- Network connectivity verification

## 📚 Documentation Requirements

### README.md Must Include
- **Quick Start**: Single command setup
- **Architecture Diagram**: Visual service layout
- **Demo Flow**: All 18 steps with descriptions
- **Troubleshooting**: Common issues and solutions
- **Manual Commands**: For exploration beyond demo
- **Security Notes**: Production considerations
- **Cleanup Instructions**: Complete environment removal

### Code Comments
- Explain complex bash operations
- Document LDAP ACL requirements
- Clarify Vault configuration parameters

## 🔐 Security Considerations

### Production-Like Practices
- **Service Account**: Use dedicated vault-bind user, not admin
- **Minimal Permissions**: LDAP ACLs with least privilege
- **Password Policies**: Complex passwords with rotation
- **Audit Trail**: Show lease management and cleanup

### Demo Safety
- **Isolated Environment**: Docker containers only
- **No Real Secrets**: All credentials are demo-specific
- **Clean Teardown**: Complete removal capability

## 🧪 Success Criteria

### Functional Requirements
- [ ] All services start cleanly with `make setup`
- [ ] Demo runs end-to-end without errors
- [ ] All 18 demo steps complete successfully
- [ ] Reset functionality provides clean state
- [ ] Documentation covers all use cases

### Quality Requirements
- [ ] Professional presentation suitable for customers
- [ ] Clear explanations of each Vault concept
- [ ] Proper error handling and recovery
- [ ] Easy to modify and extend
- [ ] Comprehensive troubleshooting guidance

## 📖 Reference Documentation
- [Vault LDAP Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/ldap)
- [Root Credential Rotation](https://developer.hashicorp.com/vault/docs/secrets/ldap#root-credential-rotation)
- [Schedule-based Rotation](https://developer.hashicorp.com/vault/docs/secrets/ldap#schedule-based-root-credential-rotation)
- [Dynamic Credentials](https://developer.hashicorp.com/vault/docs/secrets/ldap#dynamic-credentials)
- [Password Policies](https://developer.hashicorp.com/vault/docs/concepts/password-policies)

## 🎯 Delivery Expectations

### Code Quality
- **Idiomatic Scripts**: Follow bash best practices
- **Error Handling**: Proper exit codes and messages
- **Documentation**: Inline comments for complex operations
- **Modularity**: Separate scripts for different concerns

### User Experience
- **Professional Polish**: Ready for customer demonstrations
- **Educational Value**: Teaches Vault concepts effectively
- **Operational Simplicity**: Single commands for common tasks
- **Troubleshooting Support**: Clear error messages and solutions

This improved prompt provides comprehensive guidance for creating a production-quality demo environment that serves both educational and sales purposes while following security best practices.