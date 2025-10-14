# Keycloak Client Creation Walkthrough

This guide provides a step-by-step walkthrough for creating and configuring Keycloak clients using the ITL Terranetes chart. You'll learn how to add new application clients to the ITL Academy realm and configure them for different types of applications.

## Prerequisites

Before starting, ensure you have:

1. **ITL Terranetes deployed** with Keycloak modules enabled
2. **kubectl access** to the cluster with terraform-system namespace
3. **Helm installed** and configured
4. **Keycloak admin credentials** stored in Kubernetes secrets

### Verify Prerequisites

```bash
# Check Terranetes controller is running
kubectl get pods -n terraform-system -l app=terranetes-controller

# Verify Keycloak modules are enabled
kubectl get configurations -n terraform-system | grep keycloak

# Check admin credentials secret exists
kubectl get secret keycloak-admin-credentials -n terraform-system
```

## Overview of Client Types

Before creating a client, understand the different types:

### Public Clients
- **Use case**: Single-page applications (SPAs), mobile apps
- **Authentication**: Cannot securely store credentials
- **Flow**: Authorization Code with PKCE
- **Example**: React frontend, mobile app

### Confidential Clients
- **Use case**: Server-side applications, APIs
- **Authentication**: Can securely store client secrets
- **Flow**: Authorization Code, Client Credentials
- **Example**: Backend services, server-rendered apps

### Service Account Clients
- **Use case**: Machine-to-machine communication
- **Authentication**: Client credentials only
- **Flow**: Client Credentials
- **Example**: Microservices, automated tools

## Realm Configuration

Keycloak organizes clients into **realms**, which provide isolation between different environments or organizational units. You can specify which realm a client should be created in.

### Default Realm Behavior

If no realm is specified in the client configuration, clients are created in the default realm defined in your values.yaml:

```yaml
itl:
  keycloak:
    realm:
      name: "ITL-Academy"  # Default realm for all clients
```

### Specifying Custom Realms

You can override the default realm for specific clients by adding the `realm` property:

```yaml
itl:
  keycloak:
    clients:
      - name: "main-app"
        clientId: "main-app"
        # No realm specified - uses default "ITL-Academy"
        
      - name: "partner-app"
        clientId: "partner-app"
        realm: "Partners"  # Creates client in Partners realm
        
      - name: "dev-app"
        clientId: "dev-app"
        realm: "Development"  # Creates client in Development realm
```

### Common Realm Patterns

#### 1. Environment-Based Realms

```yaml
# Production applications
- name: "prod-student-portal"
  clientId: "student-portal"
  realm: "Production"
  
# Staging applications  
- name: "staging-student-portal"
  clientId: "student-portal"
  realm: "Staging"
  
# Development applications
- name: "dev-student-portal"
  clientId: "student-portal"
  realm: "Development"
```

#### 2. Organization-Based Realms

```yaml
# Internal ITL applications
- name: "itl-docs-hub"
  clientId: "itl-docs-hub"
  realm: "ITL-Academy"
  
# Partner applications
- name: "external-partner"
  clientId: "partner-client"
  realm: "Partners"
  
# Student applications
- name: "student-portal"
  clientId: "student-portal"
  realm: "Students"
```

#### 3. Function-Based Realms

```yaml
# Administrative tools
- name: "admin-dashboard"
  clientId: "admin-dashboard"
  realm: "Administration"
  
# Public-facing applications
- name: "public-website"
  clientId: "public-site"
  realm: "Public"
  
# API services
- name: "api-gateway"
  clientId: "api-gateway"
  realm: "Services"
```

### Creating Multiple Realms

To support multiple realms, you need to configure them in your Terranetes setup. Here's how to create additional realms:

```yaml
# values.yaml - Multiple realm configuration
itl:
  keycloak:
    # Default realm
    realm:
      name: "ITL-Academy"
      displayName: "ITL Academy"
    
    # Additional realms can be created via separate configurations
    additionalRealms:
      - name: "Partners"
        displayName: "External Partners"
        enabled: true
        settings:
          registrationAllowed: false
          resetPasswordAllowed: true
          rememberMe: true
          
      - name: "Development"
        displayName: "Development Environment"
        enabled: true
        settings:
          registrationAllowed: true  # Allow registration in dev
          resetPasswordAllowed: true
          rememberMe: true
          # More relaxed settings for development
          bruteForceProtected: false
          
      - name: "Students"
        displayName: "Student Portal"
        enabled: true
        settings:
          registrationAllowed: true
          verifyEmail: true
          resetPasswordAllowed: true
```

## Namespace Configuration for Client Secrets

You can specify which namespace the client secrets should be deployed to, providing flexibility for complex deployments while maintaining security boundaries.

### Default Behavior

By default, client secrets are created in the same namespace as the Terranetes deployment (typically `terraform-system`). However, you can override this to deploy secrets directly to your application namespaces.

### Configuration Options

#### 1. Single Namespace Deployment

```yaml
itl:
  keycloak:
    clients:
      - name: "my-application"
        clientId: "my-app-client"
        
        # Deploy secret to application's namespace
        secretConfig:
          name: "my-app-keycloak-credentials"
          namespace: "my-app-namespace"          # Target namespace
          labels:
            app.kubernetes.io/name: "my-app"
            app.kubernetes.io/component: "auth"
          annotations:
            description: "Keycloak credentials for my application"
```

#### 2. Multi-Namespace Deployment

```yaml
itl:
  keycloak:
    clients:
      - name: "shared-service"
        clientId: "shared-service-client"
        
        # Deploy secrets to multiple namespaces
        secrets:
          - name: "shared-service-credentials"
            namespace: "production"
            labels:
              environment: "production"
          - name: "shared-service-credentials"  
            namespace: "staging"
            labels:
              environment: "staging"
          - name: "shared-service-credentials"
            namespace: "development"
            labels:
              environment: "development"
```

#### 3. Environment-Based Namespace Patterns

```yaml
itl:
  keycloak:
    clients:
      # Production client - deploy to production namespace
      - name: "prod-api-service"
        clientId: "api-service-client"
        realm: "Production"
        secretConfig:
          name: "api-service-auth"
          namespace: "api-services-prod"
          
      # Staging client - deploy to staging namespace  
      - name: "staging-api-service"
        clientId: "api-service-client"
        realm: "Staging"
        secretConfig:
          name: "api-service-auth"
          namespace: "api-services-staging"
          
      # Development client - deploy to dev namespace
      - name: "dev-api-service"
        clientId: "api-service-client"
        realm: "Development"
        secretConfig:
          name: "api-service-auth"
          namespace: "api-services-dev"
```

### Verification Commands

After deployment, verify secrets are in the correct namespaces:

```bash
# Check secret in specific namespace
kubectl get secret my-app-keycloak-credentials -n my-app-namespace

# List all Keycloak-related secrets across namespaces
kubectl get secrets --all-namespaces -l component=keycloak-client

# Verify secret content
kubectl get secret my-app-keycloak-credentials -n my-app-namespace \
  -o jsonpath='{.data}' | jq -r 'to_entries[] | "\(.key): \(.value | @base64d)"'
```

### Security Considerations

1. **Namespace Isolation**: Ensure proper RBAC to prevent unauthorized access
2. **Cross-Namespace Access**: Be cautious about deploying secrets to multiple namespaces
3. **Secret Rotation**: Implement rotation across all target namespaces
4. **Monitoring**: Set up monitoring for secret access across namespaces

## Method 1: Adding Client via Helm Values (Recommended)

### Step 1: Update values.yaml

Add your new client to the `values.yaml` file:

```yaml
# values.yaml
itl:
  keycloak:
    enabled: true
    
    # Default realm configuration (clients will be created here unless overridden)
    realm:
      name: "ITL-Academy"
      displayName: "ITL Academy"
    
    clients:
      # Existing clients...
      - name: "terranetes-controller"
        clientId: "terranetes-controller"
        # Uses default realm "ITL-Academy"
        # ... existing config
      
      # Your new client in the default realm
      - name: "my-new-application"
        clientId: "my-app-client"
        enabled: true
        protocol: "openid-connect"
        description: "My new application client"
        # realm: "ITL-Academy"  # Optional - uses default if not specified
        
        # Client type configuration
        publicClient: false              # Set to true for SPAs/mobile
        standardFlowEnabled: true        # Enable authorization code flow
        directAccessGrantsEnabled: false # Disable direct access grants
        serviceAccountsEnabled: true     # Enable for service account
        implicitFlowEnabled: false       # Keep disabled for security
        
        # Redirect URIs (adjust for your application)
        redirectUris:
          - "https://my-app.itlusions.com/*"
          - "https://my-app.itlusions.com/auth/callback"
          - "http://localhost:3000/*"  # For development
        
        # Web origins for CORS (if needed)
        webOrigins:
          - "https://my-app.itlusions.com"
          - "http://localhost:3000"
        
        # Client roles
        roles:
          - "app-admin"
          - "app-user"
          - "app-viewer"
        
        # Secret deployment configuration
        secretConfig:
          name: "my-app-keycloak-credentials"
          namespace: "my-app-namespace"        # Deploy to application namespace
          labels:
            app.kubernetes.io/name: "my-app"
            environment: "production"
          annotations:
            description: "Keycloak client credentials"
      
      # Client in a different realm
      - name: "external-partner-app"
        clientId: "partner-app-client"
        realm: "Partners"              # Specify different realm
        enabled: true
        protocol: "openid-connect"
        description: "External partner application"
        
        publicClient: false
        standardFlowEnabled: true
        
        redirectUris:
          - "https://partner.external.com/auth/callback"
        
        roles:
          - "partner-user"
          - "partner-admin"
        
        # Partner-specific secret configuration
        secretConfig:
          name: "partner-app-credentials"
          namespace: "partner-integrations"   # Partner namespace
      
      # Client for development/testing realm
      - name: "dev-test-client"
        clientId: "dev-test-client"
        realm: "Development"           # Development realm
        enabled: true
        protocol: "openid-connect"
        
        publicClient: true            # Public for easier testing
        standardFlowEnabled: true
        
        redirectUris:
          - "http://localhost:*"      # Allow any localhost port
          - "https://dev.itlusions.com/*"
        
        webOrigins:
          - "http://localhost"
          - "https://dev.itlusions.com"
        
        # Deploy to development namespace
        secretConfig:
          name: "dev-test-credentials"
          namespace: "development"             # Development namespace
```

**Realm-Specific Configuration:**

1. **Default Realm**: If no `realm` is specified, clients are created in the default realm defined in `itl.keycloak.realm.name`
2. **Custom Realm**: Add `realm: "RealmName"` to create the client in a specific realm
3. **Multiple Realms**: You can have clients in different realms within the same configuration

### Step 2: Apply the Configuration

```bash
# Navigate to the chart directory
cd /path/to/ITL.Terranetes/chart

# Upgrade the Helm release
helm upgrade itl-terranetes . -n terraform-system

# Monitor the configuration deployment
kubectl get configurations -n terraform-system -w
```

### Step 3: Verify Client Creation

```bash
# Check if the client configuration was applied
kubectl describe configuration itl-terranetes-keycloak-clients -n terraform-system

# Check the logs of the configuration run
kubectl get runs -n terraform-system | grep keycloak-clients
kubectl logs run/<run-name> -n terraform-system

# Verify the client secrets were created
kubectl get secret itl-terranetes-keycloak-client-secrets -n terraform-system -o yaml
```

## Method 2: Creating a Standalone Client Configuration

For more complex scenarios or one-off clients, create a standalone Terranetes Configuration:

### Step 1: Create Client Configuration YAML

```yaml
# client-config.yaml
apiVersion: terraform.appvia.io/v1alpha1
kind: Configuration
metadata:
  name: my-app-keycloak-client
  namespace: terraform-system
  labels:
    app.kubernetes.io/name: my-app
    component: keycloak-client
spec:
  module:
    source: "git::https://github.com/itlusions/terraform-modules.git//keycloak/client"
    version: "v1.0.0"
  
  variables:
    # Keycloak server configuration
    - key: keycloak_url
      value: "https://sts.itlusions.com"
    
    # Specify the target realm
    - key: realm_name
      value: "ITL-Academy"  # Change this to target different realms
      # Examples:
      # value: "Partners"     # For partner applications
      # value: "Development"  # For dev/test applications
      # value: "Production"   # For production applications
    
    # Client configuration
    - key: client_id
      value: "my-app-client"
    - key: client_name
      value: "My Application"
    - key: client_description
      value: "Client for My Application"
    - key: enabled
      value: "true"
    
    # Client type settings
    - key: public_client
      value: "false"
    - key: standard_flow_enabled
      value: "true"
    - key: direct_access_grants_enabled
      value: "false"
    - key: service_accounts_enabled
      value: "true"
    
    # URLs and origins
    - key: redirect_uris
      value: |
        - "https://my-app.itlusions.com/*"
        - "https://my-app.itlusions.com/auth/callback"
        - "http://localhost:3000/*"
    
    - key: web_origins
      value: |
        - "https://my-app.itlusions.com"
        - "http://localhost:3000"
    
    # Client roles
    - key: client_roles
      value: |
        - name: "app-admin"
          description: "Application administrator"
        - name: "app-user"
          description: "Regular application user"
        - name: "app-viewer"
          description: "Read-only access"
    
    # Client attributes
    - key: client_attributes
      value: |
        access.token.lifespan: "300"
        client.session.idle.timeout: "1800"
        client.session.max.lifespan: "36000"
    
    # Secret deployment configuration
    - key: secret_name
      value: "my-app-keycloak-credentials"
    - key: secret_namespace
      value: "my-app-namespace"              # Target namespace
    - key: secret_labels
      value: |
        app.kubernetes.io/name: "my-app"
        app.kubernetes.io/component: "authentication"
    - key: secret_annotations
      value: |
        description: "Keycloak client credentials"
        created-by: "terranetes"
  
  # Reference admin credentials
  envFrom:
    - secretRef:
        name: keycloak-admin-credentials
  
  # Output secrets to specified namespace
  writeConnectionSecretsToRef:
    name: my-app-keycloak-secrets
    namespace: my-app-namespace              # Target namespace

---
# Example: Client in a different realm (Partners)
apiVersion: terraform.appvia.io/v1alpha1
kind: Configuration
metadata:
  name: partner-app-keycloak-client
  namespace: terraform-system
  labels:
    app.kubernetes.io/name: partner-app
    component: keycloak-client
spec:
  module:
    source: "git::https://github.com/itlusions/terraform-modules.git//keycloak/client"
    version: "v1.0.0"
  
  variables:
    # Keycloak server configuration
    - key: keycloak_url
      value: "https://sts.itlusions.com"
    
    # Target the Partners realm
    - key: realm_name
      value: "Partners"
    
    # Client configuration
    - key: client_id
      value: "partner-app-client"
    - key: client_name
      value: "Partner Application"
    - key: client_description
      value: "External partner integration client"
    - key: enabled
      value: "true"
    
    # Partner-specific settings
    - key: public_client
      value: "false"
    - key: standard_flow_enabled
      value: "true"
    - key: service_accounts_enabled
      value: "false"  # Partners might not need service accounts
    
    # Partner URLs
    - key: redirect_uris
      value: |
        - "https://partner.external.com/auth/callback"
        - "https://partner.external.com/sso/*"
    
    - key: web_origins
      value: |
        - "https://partner.external.com"
    
    # Partner-specific roles
    - key: client_roles
      value: |
        - name: "partner-user"
          description: "Standard partner access"
        - name: "partner-admin"
          description: "Partner administrator"
    
    # Partner secret configuration
    - key: secret_name
      value: "partner-app-keycloak-credentials"
    - key: secret_namespace
      value: "partner-integrations"          # Partner namespace
    - key: secret_labels
      value: |
        app.kubernetes.io/name: "partner-app"
        environment: "production"
        partner: "external"
  
  # Reference admin credentials
  envFrom:
    - secretRef:
        name: keycloak-admin-credentials
  
  # Output secrets to partner namespace
  writeConnectionSecretsToRef:
    name: partner-app-keycloak-secrets
    namespace: partner-integrations
```

### Step 2: Apply the Configuration

```bash
# Apply the configuration
kubectl apply -f client-config.yaml

# Monitor the progress
kubectl get configuration my-app-keycloak-client -n terraform-system -w

# Check the run status
kubectl get runs -n terraform-system | grep my-app-keycloak-client
```

## Step 3: Retrieve Client Credentials

After successful deployment, retrieve the client credentials from the specified namespace:

```bash
# Get the client secret from specific namespace
kubectl get secret my-app-keycloak-credentials -n my-app-namespace -o jsonpath='{.data.client_secret}' | base64 -d

# View all client details in the target namespace
kubectl get secret my-app-keycloak-credentials -n my-app-namespace -o yaml

# Or use a more readable format
kubectl get secret my-app-keycloak-credentials -n my-app-namespace -o json | jq -r '.data | to_entries[] | "\(.key): \(.value | @base64d)"'

# List secrets across multiple namespaces
kubectl get secrets --all-namespaces -l app.kubernetes.io/component=authentication

# Check secrets in partner namespace
kubectl get secret partner-app-keycloak-credentials -n partner-integrations -o yaml
```

## Client Configuration Examples

### Example 1: Single Page Application (SPA)

```yaml
# SPA Client (React, Vue, Angular)
- name: "student-portal-spa"
  clientId: "student-portal-spa"
  enabled: true
  protocol: "openid-connect"
  
  # SPA-specific settings
  publicClient: true                    # Public client for SPA
  standardFlowEnabled: true             # Authorization code flow
  directAccessGrantsEnabled: false     # No direct access
  serviceAccountsEnabled: false        # Not needed for SPA
  implicitFlowEnabled: false           # Deprecated, don't use
  
  # PKCE is automatically enabled for public clients
  attributes:
    "pkce.code.challenge.method": "S256"
  
  redirectUris:
    - "https://portal.itlusions.com/*"
    - "http://localhost:3000/*"
  
  webOrigins:
    - "https://portal.itlusions.com"
    - "http://localhost:3000"
  
  roles:
    - "student"
    - "instructor"
  
  # Deploy credentials to frontend namespace
  secretConfig:
    name: "student-portal-auth"
    namespace: "student-portal-frontend"
    labels:
      app: "student-portal"
      component: "spa"
```

### Example 2: Backend API Service

```yaml
# Backend API Client
- name: "api-service"
  clientId: "api-service"
  enabled: true
  protocol: "openid-connect"
  
  # API service settings
  publicClient: false                   # Confidential client
  standardFlowEnabled: false           # No user interaction
  directAccessGrantsEnabled: false    # No direct access
  serviceAccountsEnabled: true         # Machine-to-machine
  
  # No redirect URIs needed for service account
  redirectUris: []
  
  roles:
    - "api-admin"
    - "api-read"
    - "api-write"
  
  # Service account attributes
  attributes:
    "access.token.lifespan": "3600"     # 1 hour
  
  # Deploy credentials to API service namespace
  secretConfig:
    name: "api-service-credentials"
    namespace: "api-services"
    labels:
      app: "api-service"
      component: "backend"
      type: "service-account"
```

### Example 3: Mobile Application

```yaml
# Mobile App Client
- name: "mobile-app"
  clientId: "itl-mobile-app"
  enabled: true
  protocol: "openid-connect"
  
  # Mobile-specific settings
  publicClient: true                    # Cannot store secrets
  standardFlowEnabled: true            # Authorization code flow
  directAccessGrantsEnabled: false    # No direct access
  serviceAccountsEnabled: false       # Not needed
  
  # Mobile redirect URIs
  redirectUris:
    - "com.itlusions.app://oauth/callback"  # Custom URL scheme
    - "https://itlusions.com/mobile/callback" # Universal link
  
  roles:
    - "mobile-user"
  
  # Mobile-optimized token lifespans
  attributes:
    "access.token.lifespan": "900"      # 15 minutes
    "refresh.token.max.reuse": "0"      # One-time use
  
  # Deploy to mobile apps namespace
  secretConfig:
    name: "mobile-app-credentials"
    namespace: "mobile-apps"
    labels:
      app: "itl-mobile-app"
      platform: "mobile"
```

### Example 4: Multi-Environment Deployment

```yaml
# Deploy same client to multiple environments
- name: "multi-env-app"
  clientId: "my-app-client"
  enabled: true
  protocol: "openid-connect"
  
  publicClient: false
  standardFlowEnabled: true
  
  redirectUris:
    - "https://my-app.itlusions.com/*"
  
  # Deploy secrets to multiple namespaces
  secrets:
    - name: "my-app-credentials"
      namespace: "production"
      labels:
        environment: "production"
        app: "my-app"
    - name: "my-app-credentials"
      namespace: "staging"
      labels:
        environment: "staging"
        app: "my-app"
    - name: "my-app-credentials"
      namespace: "development"
      labels:
        environment: "development"
        app: "my-app"
```

## Advanced Configuration

### Setting Up Client Mappers

Client mappers transform user information into tokens. Add them via the Terraform module:

```yaml
variables:
  - key: client_mappers
    value: |
      - name: "organization-mapper"
        protocol: "openid-connect"
        protocolMapper: "oidc-usermodel-attribute-mapper"
        config:
          "user.attribute": "organization"
          "claim.name": "organization"
          "jsonType.label": "String"
          "id.token.claim": "true"
          "access.token.claim": "true"
          "userinfo.token.claim": "true"
      
      - name: "roles-mapper"
        protocol: "openid-connect"
        protocolMapper: "oidc-usermodel-realm-role-mapper"
        config:
          "claim.name": "realm_roles"
          "jsonType.label": "String"
          "multivalued": "true"
          "id.token.claim": "true"
          "access.token.claim": "true"
```

### Configuring Client Scopes

Define custom scopes for your application:

```yaml
variables:
  - key: custom_client_scopes
    value: |
      - name: "itl-academy"
        description: "ITL Academy specific claims"
        protocol: "openid-connect"
        mappers:
          - name: "course-enrollment"
            protocol: "openid-connect"
            protocolMapper: "oidc-usermodel-attribute-mapper"
            config:
              "user.attribute": "courses"
              "claim.name": "enrolled_courses"
              "jsonType.label": "String"
              "multivalued": "true"
```

## Troubleshooting

### Common Issues

#### 1. Configuration Stuck in Planning

```bash
# Check configuration status
kubectl describe configuration my-app-keycloak-client -n terraform-system

# Common causes:
# - Invalid Keycloak URL
# - Missing admin credentials
# - Network connectivity issues
```

#### 2. Invalid Redirect URI

```bash
# Error: "Invalid redirect URI"
# Solution: Ensure redirect URIs match exactly what your application sends
# Include protocol, domain, and path patterns correctly

# Example fixes:
redirectUris:
  - "https://my-app.com/auth/callback"  # Exact match
  - "https://my-app.com/*"              # Wildcard for subdirectories
```

#### 3. CORS Issues

```bash
# Error: CORS blocked requests
# Solution: Configure web origins properly

webOrigins:
  - "https://my-app.com"     # Production domain
  - "http://localhost:3000"  # Development domain
```

#### 4. Client Secret Not Generated

```bash
# Check if client is confidential
kubectl get secret my-app-keycloak-credentials -n my-app-namespace

# If secret is missing:
# 1. Ensure publicClient: false for confidential clients
# 2. Check Terraform module logs
kubectl logs -n terraform-system job/keycloak-client-xxx

# 3. Verify namespace exists
kubectl get namespace my-app-namespace

# 4. Check RBAC permissions for cross-namespace secret creation
kubectl auth can-i create secrets --namespace=my-app-namespace --as=system:serviceaccount:terraform-system:terranetes-controller
```

#### 5. Secret Not Found in Target Namespace

```bash
# Common issue: Namespace doesn't exist
kubectl create namespace my-app-namespace

# Check if secret was created in default namespace instead
kubectl get secrets -n terraform-system | grep my-app

# Verify secretConfig in values.yaml
helm get values itl-terranetes -n terraform-system

# Check Terranetes configuration
kubectl describe configuration itl-terranetes-keycloak-client-my-app -n terraform-system
```

### Debugging Commands

```bash
# View configuration details
kubectl describe configuration my-app-keycloak-client -n terraform-system

# Check recent runs
kubectl get runs -n terraform-system --sort-by=.metadata.creationTimestamp

# View run logs
kubectl logs run/my-app-keycloak-client-xxx -n terraform-system

# Check events
kubectl get events -n terraform-system --sort-by='.lastTimestamp'

# Test connectivity to Keycloak
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl -s https://sts.itlusions.com/auth/realms/ITL-Academy/.well-known/openid_configuration

# Verify secrets across namespaces
kubectl get secrets --all-namespaces -l app.kubernetes.io/component=authentication

# Check specific namespace for secrets
kubectl get secrets -n my-app-namespace -l app.kubernetes.io/name=my-app

# Verify secret content in target namespace
kubectl get secret my-app-keycloak-credentials -n my-app-namespace -o yaml

# Check RBAC permissions for namespace access
kubectl auth can-i get secrets --namespace=my-app-namespace
kubectl auth can-i create secrets --namespace=my-app-namespace --as=system:serviceaccount:terraform-system:terranetes-controller
```

## Testing Your Client

### 1. Test Authorization Flow

```bash
# Get the authorization URL for your specific realm
KEYCLOAK_URL="https://sts.itlusions.com"
REALM="ITL-Academy"  # Change this to your target realm
CLIENT_ID="my-app-client"
REDIRECT_URI="https://my-app.itlusions.com/auth/callback"

# Authorization URL for the specified realm
echo "${KEYCLOAK_URL}/auth/realms/${REALM}/protocol/openid-connect/auth?client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&response_type=code&scope=openid"

# Examples for different realms:

# For Partners realm
REALM="Partners"
echo "${KEYCLOAK_URL}/auth/realms/Partners/protocol/openid-connect/auth?client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&response_type=code&scope=openid"

# For Development realm
REALM="Development"
echo "${KEYCLOAK_URL}/auth/realms/Development/protocol/openid-connect/auth?client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&response_type=code&scope=openid"
```

### 2. Test Client Credentials Flow (for service accounts)

```bash
# Get client credentials from secret in specific namespace
CLIENT_SECRET=$(kubectl get secret my-app-keycloak-credentials -n my-app-namespace -o jsonpath='{.data.client_secret}' | base64 -d)

# Test token endpoint for specific realm
REALM="ITL-Academy"  # Specify your realm
curl -X POST \
  "https://sts.itlusions.com/auth/realms/${REALM}/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=my-app-client" \
  -d "client_secret=${CLIENT_SECRET}"

# Test with Partners realm (from partner namespace)
PARTNER_SECRET=$(kubectl get secret partner-app-keycloak-credentials -n partner-integrations -o jsonpath='{.data.client_secret}' | base64 -d)
curl -X POST \
  "https://sts.itlusions.com/auth/realms/Partners/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=partner-app-client" \
  -d "client_secret=${PARTNER_SECRET}"
```

### 3. Verify Namespace Deployment

```bash
# Check if secrets are in correct namespaces
kubectl get secrets -n my-app-namespace | grep keycloak
kubectl get secrets -n partner-integrations | grep keycloak
kubectl get secrets -n api-services | grep keycloak

# Verify secret labels and annotations
kubectl get secret my-app-keycloak-credentials -n my-app-namespace -o yaml | grep -A 10 -B 5 "labels\|annotations"

# Check multi-namespace deployments
kubectl get secrets --all-namespaces -l app=my-app | grep keycloak
```

### 3. Verify Realm Configuration

```bash
# Check realm configuration endpoints
curl -s "https://sts.itlusions.com/auth/realms/ITL-Academy/.well-known/openid_configuration" | jq .

# Check Partners realm
curl -s "https://sts.itlusions.com/auth/realms/Partners/.well-known/openid_configuration" | jq .

# Check Development realm
curl -s "https://sts.itlusions.com/auth/realms/Development/.well-known/openid_configuration" | jq .
```

### 4. Verify Token Content

```bash
# Decode JWT token (install jq and jwt-cli first)
TOKEN="your-jwt-token-here"
echo $TOKEN | jwt decode -

# Check the 'iss' (issuer) claim to verify the realm
echo $TOKEN | jwt decode - | jq '.iss'
# Should return: "https://sts.itlusions.com/auth/realms/YourRealmName"
```

## Integration Examples

### React/JavaScript Application

```javascript
// Install: npm install oidc-client-ts

import { UserManager } from 'oidc-client-ts';

// Configuration for ITL-Academy realm
const userManagerITL = new UserManager({
  authority: 'https://sts.itlusions.com/auth/realms/ITL-Academy',
  client_id: 'my-app-client',
  redirect_uri: 'https://my-app.itlusions.com/auth/callback',
  post_logout_redirect_uri: 'https://my-app.itlusions.com',
  response_type: 'code',
  scope: 'openid profile email',
  loadUserInfo: true,
});

// Configuration for Partners realm
const userManagerPartners = new UserManager({
  authority: 'https://sts.itlusions.com/auth/realms/Partners',
  client_id: 'partner-app-client',
  redirect_uri: 'https://partner.external.com/auth/callback',
  post_logout_redirect_uri: 'https://partner.external.com',
  response_type: 'code',
  scope: 'openid profile email',
  loadUserInfo: true,
});

// Configuration for Development realm
const userManagerDev = new UserManager({
  authority: 'https://sts.itlusions.com/auth/realms/Development',
  client_id: 'dev-test-client',
  redirect_uri: 'https://dev.itlusions.com/auth/callback',
  post_logout_redirect_uri: 'https://dev.itlusions.com',
  response_type: 'code',
  scope: 'openid profile email',
  loadUserInfo: true,
});

// Usage based on environment
const getUserManager = (environment) => {
  switch (environment) {
    case 'production':
      return userManagerITL;
    case 'partner':
      return userManagerPartners;
    case 'development':
      return userManagerDev;
    default:
      return userManagerITL;
  }
};

// Login
const userManager = getUserManager(process.env.REACT_APP_ENVIRONMENT);
await userManager.signinRedirect();

// Handle callback
await userManager.signinRedirectCallback();

// Get user info
const user = await userManager.getUser();
console.log(user.profile);
```

### Node.js/Express Backend

```javascript
// Install: npm install express-openid-connect

const { auth } = require('express-openid-connect');

// Configuration for different realms
const getAuthConfig = (realm) => {
  const baseConfig = {
    authRequired: false,
    auth0Logout: true,
    baseURL: process.env.BASE_URL,
    secret: process.env.SESSION_SECRET,
  };

  switch (realm) {
    case 'ITL-Academy':
      return {
        ...baseConfig,
        issuerBaseURL: 'https://sts.itlusions.com/auth/realms/ITL-Academy',
        clientID: 'my-app-client',
        clientSecret: process.env.KEYCLOAK_CLIENT_SECRET_ITL,
        // Secret mounted from: my-app-namespace/my-app-keycloak-credentials
      };
    
    case 'Partners':
      return {
        ...baseConfig,
        issuerBaseURL: 'https://sts.itlusions.com/auth/realms/Partners',
        clientID: 'partner-app-client',
        clientSecret: process.env.KEYCLOAK_CLIENT_SECRET_PARTNERS,
        // Secret mounted from: partner-integrations/partner-app-keycloak-credentials
      };
    
    case 'Development':
      return {
        ...baseConfig,
        issuerBaseURL: 'https://sts.itlusions.com/auth/realms/Development',
        clientID: 'dev-test-client',
        clientSecret: process.env.KEYCLOAK_CLIENT_SECRET_DEV,
        // Secret mounted from: development/dev-test-credentials
      };
    
    default:
      throw new Error(`Unknown realm: ${realm}`);
  }
};

// Use based on environment
const realm = process.env.KEYCLOAK_REALM || 'ITL-Academy';
const config = getAuthConfig(realm);
app.use(auth(config));

// Protected route
app.get('/protected', requiresAuth(), (req, res) => {
  res.send(`Hello ${req.oidc.user.name} from ${realm} realm`);
});

// Multi-realm support in single application
app.get('/auth/:realm', (req, res) => {
  const { realm } = req.params;
  const config = getAuthConfig(realm);
  
  // Dynamically configure auth for different realms
  const authMiddleware = auth(config);
  authMiddleware(req, res, () => {
    res.redirect('/dashboard');
  });
});
```

### Kubernetes Deployment with Namespace-Specific Secrets

```yaml
# deployment.yaml - Application deployment with namespace-specific secrets
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: my-app-namespace
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: my-app:latest
        env:
        # Load client credentials from namespace-specific secret
        - name: KEYCLOAK_CLIENT_SECRET_ITL
          valueFrom:
            secretKeyRef:
              name: my-app-keycloak-credentials    # Secret in same namespace
              key: client_secret
        - name: KEYCLOAK_CLIENT_ID
          valueFrom:
            secretKeyRef:
              name: my-app-keycloak-credentials
              key: client_id
        - name: KEYCLOAK_REALM
          value: "ITL-Academy"
        - name: KEYCLOAK_URL
          value: "https://sts.itlusions.com"
        ports:
        - containerPort: 3000

---
# Example: Multi-environment deployment with different secrets
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-service
  namespace: api-services
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-service
  template:
    metadata:
      labels:
        app: api-service
    spec:
      containers:
      - name: api-service
        image: api-service:latest
        env:
        # Production credentials
        - name: KEYCLOAK_CLIENT_SECRET
          valueFrom:
            secretKeyRef:
              name: api-service-credentials        # Deployed to api-services namespace
              key: client_secret
        - name: KEYCLOAK_CLIENT_ID
          valueFrom:
            secretKeyRef:
              name: api-service-credentials
              key: client_id
        # Service account client for machine-to-machine
        - name: KEYCLOAK_GRANT_TYPE
          value: "client_credentials"
        - name: KEYCLOAK_REALM
          value: "Production"
```

### Environment-Specific Configuration

```javascript
// config/keycloak.js
const getKeycloakConfig = () => {
  const environment = process.env.NODE_ENV;
  const realmMap = {
    'development': {
      realm: 'Development',
      clientId: 'dev-test-client',
      url: 'https://sts.itlusions.com'
    },
    'staging': {
      realm: 'Staging',
      clientId: 'staging-app-client',
      url: 'https://sts.itlusions.com'
    },
    'production': {
      realm: 'ITL-Academy',
      clientId: 'my-app-client',
      url: 'https://sts.itlusions.com'
    }
  };

  return realmMap[environment] || realmMap['development'];
};

// Usage in your application
const keycloakConfig = getKeycloakConfig();
console.log(`Using realm: ${keycloakConfig.realm}`);
```

## Security Best Practices

1. **Use HTTPS**: Always use HTTPS in production
2. **Restrict Redirect URIs**: Be specific with redirect URI patterns
3. **Short Token Lifespans**: Use short access token lifespans (5-15 minutes)
4. **Secure Client Secrets**: Store secrets in Kubernetes secrets, not in code
5. **Enable PKCE**: Always enable PKCE for public clients
6. **Regular Secret Rotation**: Implement regular client secret rotation
7. **Monitor Access**: Set up monitoring and alerting for authentication events

## Next Steps

After creating your client:

1. **Configure User Groups**: Assign users to appropriate groups for role mapping
2. **Set Up Monitoring**: Monitor authentication metrics and errors
3. **Implement Logout**: Configure proper logout flows
4. **Add Custom Claims**: Use mappers to add application-specific claims
5. **Test Thoroughly**: Test all flows in development before production deployment

For more advanced configurations, see:
- [KEYCLOAK_MODULES.md](KEYCLOAK_MODULES.md) - Complete module documentation
- [Keycloak Documentation](https://www.keycloak.org/documentation) - Official Keycloak docs
- [ITL Authentication Guide](https://wiki.itlusions.com/auth) - ITL-specific authentication patterns