# Keycloak Modules for ITL Terranetes

This document describes the Keycloak integration modules available in the ITL Terranetes chart. These modules provide comprehensive Keycloak management through Terraform using the Terranetes controller.

## Overview

The ITL Terranetes chart includes several Keycloak-related Terraform modules to manage authentication and authorization infrastructure:

- **keycloak-server**: Deploy and configure Keycloak server
- **keycloak-realm**: Manage Keycloak realms with ITL-specific settings
- **keycloak-client**: Create and configure application clients
- **keycloak-identity-provider**: Set up external identity providers (Azure AD, GitHub)
- **keycloak-theme**: Deploy ITL-branded themes
- **keycloak-backup**: Configure automated backup solutions

## Module Configuration

### Enabling Keycloak Modules

In your `values.yaml`:

```yaml
itl:
  keycloak:
    enabled: true
    
  modules:
    keycloak:
      enabled: true
      modules:
        - name: "keycloak-realm"
          source: "git::https://github.com/itlusions/terraform-modules.git//keycloak/realm"
          version: "v1.0.0"
        # ... other modules
```

### Keycloak Server Configuration

```yaml
itl:
  keycloak:
    server:
      enabled: true
      url: "https://sts.itlusions.com"
      adminRealm: "master"
      adminCredentials:
        secretName: "keycloak-admin-credentials"
        usernameKey: "username"
        passwordKey: "password"
```

### Realm Configuration

The chart creates an ITL Academy realm with specific settings:

```yaml
itl:
  keycloak:
    realm:
      name: "ITL-Academy"
      displayName: "ITL Academy"
      enabled: true
      settings:
        registrationAllowed: false
        registrationEmailAsUsername: true
        rememberMe: true
        verifyEmail: true
        resetPasswordAllowed: true
        ssoSessionIdleTimeout: 1800  # 30 minutes
        ssoSessionMaxLifespan: 36000  # 10 hours
        bruteForceProtected: true
        failureFactor: 5
```

### Client Configuration

Pre-configured clients for ITL applications:

```yaml
itl:
  keycloak:
    clients:
      - name: "terranetes-controller"
        clientId: "terranetes-controller"
        enabled: true
        protocol: "openid-connect"
        publicClient: false
        standardFlowEnabled: true
        serviceAccountsEnabled: true
        redirectUris:
          - "https://terraform.itlusions.com/*"
        roles:
          - "terraform-admin"
          - "terraform-user"
          - "terraform-viewer"
```

### User Groups

Predefined user groups with role assignments:

```yaml
itl:
  keycloak:
    groups:
      - name: "itl-staff"
        displayName: "ITL Staff"
        description: "Full access to ITL systems"
        realmRoles:
          - "admin"
        clientRoles:
          terranetes-controller:
            - "terraform-admin"
```

### Identity Providers

External authentication integration:

```yaml
itl:
  keycloak:
    identityProviders:
      azureAD:
        enabled: true
        alias: "azure-ad"
        displayName: "ITL Azure AD"
        defaultGroups:
          - "itl-staff"
      github:
        enabled: true
        alias: "github"
        displayName: "GitHub"
        defaultGroups:
          - "instructors"
```

## Generated Resources

When deployed, the chart creates several Kubernetes resources:

### ConfigMaps

- `<release>-keycloak-config`: Contains Keycloak configuration data
- Client, group, and identity provider configurations

### Secrets

- `<release>-keycloak-admin-ref`: References to admin credentials
- `<release>-keycloak-realm-secrets`: Realm connection secrets
- `<release>-keycloak-client-secrets`: Client credentials and details
- `<release>-keycloak-idp-secrets`: Identity provider configurations

### Terranetes Configurations

- `<release>-keycloak-realm`: Manages the ITL Academy realm
- `<release>-keycloak-clients`: Creates and configures application clients
- `<release>-keycloak-identity-providers`: Sets up external authentication

## Usage Examples

> **📖 Detailed Walkthrough**: For a comprehensive step-by-step guide on creating Keycloak clients, see [CLIENT_CREATION_WALKTHROUGH.md](CLIENT_CREATION_WALKTHROUGH.md)

### Basic Realm Setup

Deploy a basic ITL Academy realm:

```bash
# Install the chart with Keycloak enabled
helm install itl-terranetes ./chart \
  --set itl.keycloak.enabled=true \
  --set itl.keycloak.server.url=https://sts.itlusions.com
```

### Adding a New Client

Add a new application client:

```yaml
# In values.yaml
itl:
  keycloak:
    clients:
      - name: "new-application"
        clientId: "new-app"
        enabled: true
        protocol: "openid-connect"
        publicClient: false
        redirectUris:
          - "https://new-app.itlusions.com/*"
        roles:
          - "app-admin"
          - "app-user"
```

### Configuring Azure AD Integration

Set up Azure AD as an identity provider:

```bash
# Create Azure AD credentials secret
kubectl create secret generic azure-ad-credentials \
  --from-literal=client-id="${AZURE_CLIENT_ID}" \
  --from-literal=client-secret="${AZURE_CLIENT_SECRET}" \
  --from-literal=tenant-id="${AZURE_TENANT_ID}" \
  -n terraform-system

# Enable Azure AD in values.yaml
# itl.keycloak.identityProviders.azureAD.enabled: true
```

## Required Secrets

Before deploying, ensure these secrets exist:

### Keycloak Admin Credentials

```bash
kubectl create secret generic keycloak-admin-credentials \
  --from-literal=username="admin" \
  --from-literal=password="secure-password" \
  -n terraform-system
```

### Azure AD Credentials (if enabled)

```bash
kubectl create secret generic azure-ad-credentials \
  --from-literal=client-id="your-azure-client-id" \
  --from-literal=client-secret="your-azure-client-secret" \
  --from-literal=tenant-id="your-azure-tenant-id" \
  -n terraform-system
```

### GitHub OAuth Credentials (if enabled)

```bash
kubectl create secret generic github-oauth-credentials \
  --from-literal=client-id="your-github-client-id" \
  --from-literal=client-secret="your-github-client-secret" \
  -n terraform-system
```

## Monitoring and Troubleshooting

### Check Configuration Status

```bash
# Check Terranetes configurations
kubectl get configurations -n terraform-system

# Check specific Keycloak configurations
kubectl get configuration -l component=keycloak-realm -n terraform-system
kubectl get configuration -l component=keycloak-clients -n terraform-system

# View configuration details
kubectl describe configuration itl-terranetes-keycloak-realm -n terraform-system
```

### View Generated Secrets

```bash
# List Keycloak-related secrets
kubectl get secrets -l component=keycloak-credentials -n terraform-system

# View realm secrets
kubectl get secret itl-terranetes-keycloak-realm-secrets -o yaml -n terraform-system
```

### Check Logs

```bash
# Check Terranetes controller logs
kubectl logs -n terraform-system deployment/terranetes-controller-manager

# Check specific configuration runs
kubectl get runs -n terraform-system
kubectl logs run/keycloak-realm-xxxxx -n terraform-system
```

## Security Considerations

1. **Secret Management**: Use proper secret management solutions for production
2. **Network Policies**: Ensure network policies restrict access to Keycloak
3. **RBAC**: Configure proper Kubernetes RBAC for Terranetes operations
4. **Backup**: Enable automated backup for Keycloak data
5. **Monitoring**: Set up monitoring and alerting for authentication services

## Integration with ITL Services

The Keycloak modules integrate with other ITL services:

- **ITL Documentation Hub**: Authentication and authorization
- **Student Portal**: User management and course access
- **Terranetes Controller**: Infrastructure access control
- **Monitoring Stack**: Service authentication

## Contributing

To contribute to the Keycloak modules:

1. Create Terraform modules in the `terraform-modules` repository
2. Update the module references in `values.yaml`
3. Test the configuration with Terranetes
4. Submit a pull request with documentation updates

## Support

For support with Keycloak modules:

1. Check the Terranetes controller logs
2. Review the generated configurations
3. Contact the ITL DevOps team
4. Submit issues to the terraform-modules repository