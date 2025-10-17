# Keycloak Setup with ITL Terranetes - Simple Guide

## Overview

This guide shows you how to set up Keycloak authentication with ITL Terranetes in 3 simple steps:

1. **Create Terraform Client in Keycloak**
2. **Configure Kubernetes Secret**
3. **Deploy with Helm**

---

## Step 1: Create Terraform Client in Keycloak

### Access Keycloak Admin Console
1. Go to `https://sts.itlusions.com`
2. Click **Administration Console**
3. Login with admin credentials
4. Select **master** realm

### Create Client
1. Go to **Clients** → **Create client**
2. Fill in:
   - **Client ID**: `terraform-admin`
   - **Client type**: `OpenID Connect`
   - **Client authentication**: `ON`
   - **Service accounts roles**: `ON`
   - All other flows: `OFF`
3. **Save**

### Set Permissions
1. Go to **Service Account Roles** tab
2. **Assign role** → Filter by clients → **realm-management**
3. Assign: `manage-realm`, `manage-clients`, `manage-users`

### Get Client Secret
1. Go to **Credentials** tab
2. Copy the **Client secret**

---

## Step 2: Configure Kubernetes Secret

Create the authentication secret:

```bash
kubectl create secret generic keycloak-terraform-provider \
  --from-literal=client_id="terraform-admin" \
  --from-literal=client_secret="YOUR_CLIENT_SECRET_HERE" \
  --namespace=terraform-system
```

---

## Step 3: Deploy with Helm

### Basic Configuration

Create or update your `values.yaml`:

```yaml
# Keycloak Provider
terranetes-controller:
  providers:
    keycloak:
      source: mrparkers/keycloak
      version: "4.4.0"
      secretRef:
        name: keycloak-terraform-provider
        namespace: terraform-system

# ITL Keycloak Setup
itl:
  keycloak:
    enabled: true
    server:
      url: "https://sts.itlusions.com"
    
    # Create ITL Academy Realm
    realm:
      enabled: true
      name: "ITL-Academy"
    
    # Example Client
    clients:
      - name: "student-portal"
        clientId: "student-portal"
        accessType: "CONFIDENTIAL"
        redirectUris:
          - "https://portal.itlusions.com/auth/callback"
        enabled: true
```

### Deploy

```bash
helm upgrade --install terranetes ./chart \
  --namespace terraform-system \
  --create-namespace \
  -f values.yaml
```

---

## Verification

### Check Deployment Status

```bash
# Check if everything is running
kubectl get pods -n terraform-system

# Check Keycloak configurations
kubectl get configurations -n terraform-system | grep keycloak

# View configuration status
kubectl get configuration student-portal -n terraform-system
```

### Get Client Credentials

```bash
# Get client secret for your application
kubectl get secret student-portal-outputs -n terraform-system \
  -o jsonpath='{.data.client_secret}' | base64 -d
```

---

## Quick Client Types

### Web Application
```yaml
- name: "my-webapp"
  clientId: "my-webapp"
  accessType: "CONFIDENTIAL"
  redirectUris:
    - "https://myapp.com/callback"
```

### Single Page App (SPA)
```yaml
- name: "my-spa"
  clientId: "my-spa"
  accessType: "PUBLIC"
  pkceMethod: "S256"
  redirectUris:
    - "https://myapp.com/callback"
```

### API Service
```yaml
- name: "my-api"
  clientId: "my-api"
  accessType: "CONFIDENTIAL"
  serviceAccountsEnabled: true
  standardFlowEnabled: false
```

### Mobile App
```yaml
- name: "my-mobile"
  clientId: "my-mobile"
  accessType: "PUBLIC"
  pkceMethod: "S256"
  redirectUris:
    - "com.myapp://callback"
```

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Client not created | Check `enabled: true` and realm exists |
| Secret not found | Verify client credentials secret exists |
| Permission denied | Ensure service account has proper roles |
| Redirect errors | Check URIs match exactly |

### Debug Commands

```bash
# Check provider status
kubectl get providers -n terraform-system

# View controller logs
kubectl logs -n terraform-system deployment/terranetes-controller

# Check configuration details
kubectl describe configuration student-portal -n terraform-system
```

---

## Complete Example

Here's a complete working example:

```yaml
# values.yaml
terranetes-controller:
  providers:
    keycloak:
      source: mrparkers/keycloak
      version: "4.4.0"
      secretRef:
        name: keycloak-terraform-provider
        namespace: terraform-system

itl:
  organization:
    name: "ITlusions"
    domain: "itlusions.com"
  
  environment:
    name: "production"
    region: "westeurope"
  
  keycloak:
    enabled: true
    server:
      url: "https://sts.itlusions.com"
    
    realm:
      enabled: true
      name: "ITL-Academy"
      displayName: "ITL Academy"
    
    clients:
      - name: "student-portal"
        clientId: "student-portal"
        displayName: "Student Portal"
        accessType: "CONFIDENTIAL"
        redirectUris:
          - "https://portal.itlusions.com/auth/callback"
        webOrigins:
          - "https://portal.itlusions.com"
        roles:
          - name: "student"
            description: "Student access"
          - name: "teacher"
            description: "Teacher access"
        enabled: true
      
      - name: "mobile-app"
        clientId: "itl-mobile"
        displayName: "ITL Mobile App"
        accessType: "PUBLIC"
        pkceMethod: "S256"
        redirectUris:
          - "com.itlusions.app://callback"
        enabled: true
```

Deploy with:
```bash
helm upgrade --install terranetes ./chart \
  --namespace terraform-system \
  --create-namespace \
  -f values.yaml
```

That's it! Your Keycloak integration is ready to use.