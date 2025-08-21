# HashiCorp Vault LDAP Service Account Rotation Demo

## 🎯 Project Goal
Create a command-line demo showing HashiCorp Vault's LDAP secrets engine for service account rotation. Should be easy to run, reset, and suitable for presentations.

## 🏗️ Technical Requirements

### Environment
- **Platform**: macOS with Docker Compose
- **Demo Tool**: Use `demo-magic.sh` for paced presentation
- **Interface**: Command-line with nice visual formatting

### Services
- **Vault Enterprise**: Latest image, port 8200, use provided `vault.hclic` license
- **OpenLDAP**: Standard image, port 389, domain `demo.hashicorp.com`

### LDAP Users Needed
- **vault-bind**: Service account for Vault to use (not admin account)
- **static-account**: Existing user for static role demo
- **admin**: LDAP admin for setup only

## 📁 Project Files
```
├── docker-compose.yml    # Services setup
├── Makefile             # Commands (start, demo, reset, clean)
├── README.md            # Good documentation
├── demo.sh              # Main demo script
├── reset-demo.sh        # Reset between runs
├── vault-init.sh        # Setup script
└── vault.hclic          # License file
```

## 🎭 Demo Flow
Show these key Vault LDAP features in order:

1. **LDAP directory overview** - Show existing users
2. **Vault status** - Confirm it's running
3. **Enable LDAP engine** - Configure integration
4. **Root rotation** - Vault rotates its own bind password
5. **Schedule rotation** - Set up automatic rotation
6. **Password policy** - Show complexity rules
7. **Static role** - Manage existing service account
8. **Manual rotation** - Rotate static account password
9. **Dynamic role** - Create temporary users
10. **Generate credentials** - Show multiple dynamic users
11. **Show LDAP users** - Display created dynamic users
12. **Lease management** - Show active leases and cleanup

## 🎨 User Experience
- **Visual**: Use box formatting for step headers (like ╔══╗)
- **Colors**: Blue headers, emojis for visual appeal
- **Reset**: `make reset` cleans everything for next demo run
- **Error handling**: Graceful failures with helpful messages

## 🔧 Must-Have Commands
```bash
make setup    # Start everything
make demo     # Run the demo
make reset    # Clean state for next run  
make clean    # Remove everything
```

## 📚 Documentation
- **README**: Quick start, troubleshooting, all commands
- **Comments**: Explain complex parts in scripts

## ✅ Success Criteria
- Demo runs smoothly from start to finish
- Easy to reset and run multiple times
- Good documentation for others to use
- Professional looking output

## 📖 References
- [Vault LDAP Docs](https://developer.hashicorp.com/vault/docs/secrets/ldap)
- [Root Rotation](https://developer.hashicorp.com/vault/docs/secrets/ldap#root-credential-rotation)
- [Dynamic Credentials](https://developer.hashicorp.com/vault/docs/secrets/ldap#dynamic-credentials)