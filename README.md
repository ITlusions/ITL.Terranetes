-# ITL Terranetes Controller

This Helm chart deploys the Terranetes Controller for ITL Academy, providing infrastructure-as-code capabilities with GitOps workflows, policy enforcement, and cost management. This is a wrapper chart that extends the official Terranetes controller with ITL-specific configurations, monitoring, and integrations.

## Overview

Terranetes is a Kubernetes-native solution that enables teams to provision and manage cloud infrastructure using Terraform in a GitOps manner. This ITL-specific deployment includes:

- **Self-Service Infrastructure**: Teams can provision cloud resources through Kubernetes CRDs
- **Application-Owned Configurations**: Applications can manage their own Terraform configurations in their namespaces
- **Flexible Secret Management**: Deploy client secrets to any namespace for better isolation
- **Policy Enforcement**: Security and compliance policies using Checkov
- **Cost Management**: Cost estimation and budget controls with configurable thresholds
- **GitOps Integration**: Native integration with ArgoCD and Flux
- **Approval Workflows**: Multi-stage approval processes for production changes
- **Drift Detection**: Automatic detection and alerting of infrastructure drift
- **ITL Integrations**: Pre-configured for ITL's Keycloak, Prometheus, and Grafana stack
- **Automated Backup**: Scheduled backup of Terraform state and configurations
- **Network Security**: Enhanced network policies and pod security standards
- **Multi-Namespace Support**: Single controller manages configurations across all namespaces

## Default Deployments

When you deploy the ITL Terranetes chart with default configuration, the following resources are created by default:

### ✅ **Always Deployed (Default: Enabled)**

#### Core Terranetes Components
- **Terranetes Controller** - Main controller deployment with 2 replicas for HA
- **ServiceAccount & RBAC** - Controller and executor service accounts with cluster-wide permissions
- **Webhooks** - Admission controllers for Configuration and Revision validation
- **NetworkPolicies** - Security policies allowing controller and executor communication
- **ConfigMaps** - Helm template overrides and job configurations

#### ITL-Specific Resources  
- **Keycloak Provider** - Terraform provider configuration for Keycloak authentication
- **ITL Academy Realm** - Keycloak realm (`ITL-Academy`) with ITL-specific settings
- **Student Portal Client** - Default SPA client for the student portal application
- **Backup CronJob** - Automated backup of Terraform state every 6 hours
- **Monitoring Resources** - ServiceMonitor for Prometheus metrics collection

### ⚠️ **Conditionally Deployed (Default: Disabled)**

#### Additional Keycloak Clients
- **Terranetes Controller Client** - OIDC client for controller authentication (`enabled: false`)
- **ITL Documentation Hub Client** - Client for docs portal (`enabled: false`)

#### Cloud Provider Support
- **Azure Provider** - Azure credentials and provider configuration (`enabled: false`)
- **AWS Provider** - AWS credentials and provider configuration (`enabled: false`)
- **Google Cloud Provider** - GCP credentials and provider configuration (`enabled: false`)

#### Monitoring & Observability
- **Prometheus Integration** - Full Prometheus monitoring stack (`enabled: false`)
- **Grafana Dashboards** - Infrastructure monitoring dashboards (`enabled: false`)
- **Grafana Client** - Keycloak OIDC client for Grafana (`enabled: false`)

#### Additional Features
- **Security Scanning** - Checkov policy enforcement (`security.imageScanning: true`)
- **Cost Management** - Infracost integration (`costs.enabled: false`)
- **ArgoCD Integration** - GitOps workflow integration (`integrations.argocd.enabled: false`)

### 📋 **Resource Summary by Namespace**

#### `terraform-system` (Controller Namespace)
```
Deployments: terranetes-controller
Services: terranetes-controller, terranetes-controller-webhooks
Secrets: keycloak-terraform-provider, ca-certificates
ConfigMaps: terranetes-controller-config, job-templates
NetworkPolicies: terranetes-controller-network-policy
CronJobs: terraform-state-backup
ServiceMonitors: terranetes-controller-metrics
```

#### `itl-academy` Realm (Keycloak Resources)
```
Configurations: itl-academy-realm, student-portal
Secrets: itl-academy-realm-outputs, student-portal-outputs
```

### 🔧 **To Enable Optional Resources**

To enable additional components, update your `values.yaml`:

```yaml
# Enable additional Keycloak clients
itl:
  keycloak:
    clients:
      - name: "terranetes-controller"
        enabled: true  # Enable controller OIDC client

# Enable cloud provider support
itl:
  providers:
    azure:
      enabled: true  # Enable Azure provider

# Enable monitoring stack
monitoring:
  prometheus:
    enabled: true  # Enable Prometheus integration
  grafana:
    enabled: true  # Enable Grafana dashboards

# Enable additional integrations
integrations:
  argocd:
    enabled: true  # Enable ArgoCD integration
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    ITL Terranetes Controller                    │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────────┐ │
│  │ Terranetes       │  │ ITL ConfigMap    │  │ Network        │ │
│  │ Controller       │  │ - Organization   │  │ Policies       │ │
│  │ (Official)       │  │ - Environments   │  │ - Controller   │ │
│  │ Watches ALL      │  │ - Policies       │  │ - Executors    │ │
│  │ Namespaces       │  │ - Keycloak Mods  │  │                │ │
│  └──────────────────┘  └──────────────────┘  └────────────────┘ │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────────┐ │
│  │ ServiceMonitor   │  │ Backup CronJob   │  │ Grafana        │ │
│  │ - Metrics        │  │ - State Backup   │  │ Dashboard      │ │
│  │ - ITL Labels     │  │ - Config Backup  │  │ - Infra Metrics│ │
│  └──────────────────┘  └──────────────────┘  └────────────────┘ │
└─────────────────────────────────────────────────────────────────┘

Application Namespace Architecture:
┌─────────────────────────────────────────────────────────────────┐
│                   Multi-Namespace Support                       │
├─────────────────────────────────────────────────────────────────┤
│ terraform-system          │ my-app-namespace      │ api-namespace│
│ ┌─────────────────────┐   │ ┌─────────────────┐   │ ┌──────────┐ │
│ │ Controller          │◄──┤ │ Configuration   │   │ │ Config   │ │
│ │ (Watches All)       │   │ │ + Secrets       │   │ │ + Secrets│ │
│ │                     │   │ │ + Application   │   │ │ + App    │ │
│ └─────────────────────┘   │ └─────────────────┘   │ └──────────┘ │
│                           │                       │              │
│ ┌─────────────────────┐   │ ┌─────────────────┐   │ ┌──────────┐ │
│ │ Keycloak Modules    │   │ │ Keycloak Client │   │ │ API Auth │ │
│ │ + Templates         │   │ │ Credentials     │   │ │ Secrets  │ │
│ └─────────────────────┘   │ └─────────────────┘   │ └──────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

1. **Kubernetes Cluster**: Version 1.24+
2. **Helm**: Version 3.8+
3. **Cloud Credentials**: Appropriate cloud provider credentials stored as Kubernetes secrets
4. **ArgoCD** (optional): For GitOps workflow integration
5. **Prometheus** (optional): For monitoring and alerting

## Installation

### Quick Install

```bash
# Add the ITL Helm repository (OCI registry)
helm repo add itl-terranetes oci://ghcr.io/itlusions/helm/terranetes

# Install the chart
helm install terranetes itl-terranetes/itl-terranetes-controller \
  --create-namespace \
  --namespace terraform-system \
  --values values.yaml
```

### Install from GitHub Container Registry (OCI)

```bash
# Install specific version from GitHub Container Registry
helm install terranetes oci://ghcr.io/itlusions/helm/terranetes \
  --version v0.1.0 \
  --create-namespace \
  --namespace terraform-system \
  --values values.yaml
```

### Install Latest Version

```bash
# Install latest version from GitHub Container Registry
helm install terranetes oci://ghcr.io/itlusions/helm/terranetes \
  --version latest \
  --create-namespace \
  --namespace terraform-system \
  --values values.yaml
```
  --values values.yaml
```

### Install from Source

```bash
# Clone the repository
git clone https://github.com/ITlusions/ITL.Terranetes.git
cd ITL.Terranetes

# Add required dependencies
helm repo add appvia https://terranetes-controller.appvia.io
helm repo update

# Install with ITL-specific configuration
helm install itl-terranetes ./chart \
  --create-namespace \
  --namespace terraform-system \
  --values values.yaml
```

### Basic Values Configuration

Create a `values.yaml` file:

```yaml
# ITL Terranetes Controller Configuration
itl:
  enabled: true
  organization: "your-org"
  environment: "production"
  
  keycloak:
    enabled: true
    realm: "itl-academy"
    clientId: "terranetes"
    
  monitoring:
    enabled: true
    namespace: "monitoring"
    
  backup:
    enabled: true
    schedule: "0 2 * * *"
    retentionDays: 30

terranetes-controller:
  enabled: true
  
  controller:
    costs:
      enabled: true
      secret: "infracost-api"
      
    policy:
      enabled: true
      source: "https://github.com/itlusions/terraform-policies"
      
  replicaCount: 1
  
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 100m
      memory: 128Mi
```

### Verify Installation

```bash
# Check the deployment
kubectl get pods -n terraform-system

# Check the CRDs
kubectl get crd | grep terranetes

# View controller logs
kubectl logs -n terraform-system deployment/terranetes-controller

# Verify ITL-specific resources
kubectl get configmap -n terraform-system -l app.kubernetes.io/managed-by=Helm
kubectl get servicemonitor -n terraform-system
kubectl get networkpolicy -n terraform-system

# Verify multi-namespace support
kubectl auth can-i get configurations --all-namespaces --as=system:serviceaccount:terraform-system:terranetes-controller
```

### 4. Controller Reuse Pattern

**Important**: If the Terranetes controller is already installed in your cluster, it will be **reused**, not reinstalled. The controller can manage configurations across multiple namespaces and applications.

```bash
# Check if controller already exists
kubectl get deployment terranetes-controller -n terraform-system

# Add this chart as a dependency to your applications
# The existing controller will manage the new configurations
```

## Configuration

### Chart Structure

This chart is composed of the following key components:

- **Base Controller**: Official Terranetes controller (dependency)
- **ITL ConfigMap**: Organization and environment-specific configuration
- **ServiceMonitor**: Prometheus metrics collection with ITL labels
- **NetworkPolicy**: Secure network access controls
- **Backup CronJob**: Automated state and configuration backup
- **Grafana Dashboard**: Pre-configured monitoring dashboard

### Default Configuration

The chart includes ITL-specific defaults:

- **Organization**: ITlusions (itlusions.com)
- **Environment**: Production (westeurope region)
- **Namespace**: `terraform-system`
- **Replicas**: 2 (for high availability)
- **Security**: Enhanced security policies and network restrictions
- **Monitoring**: Prometheus metrics with ITL-specific labels
- **Backup**: Daily automated backup of Terraform state
- **Integration**: Pre-configured for ITL's existing infrastructure

### Key Configuration Files

#### ITL ConfigMap (`itl-config.yaml`)
Generated from chart values and includes:
- Organization metadata
- Environment configuration
- Policy definitions
- Module registry settings
- Integration endpoints

#### Common Modules (`common-modules.yaml`)
Pre-configured Terraform modules for ITL use cases:
- Azure VM provisioning
- Development environments
- Student lab environments

### Cloud Provider Setup

#### Azure (Primary for ITL)

```bash
# Create Azure service principal
az ad sp create-for-rbac --name "terranetes-sp" --role "Contributor" \
  --scopes "/subscriptions/{subscription-id}"

# Create Kubernetes secret
kubectl create secret generic azure-credentials \
  --from-literal=ARM_CLIENT_ID="<client-id>" \
  --from-literal=ARM_CLIENT_SECRET="<client-secret>" \
  --from-literal=ARM_SUBSCRIPTION_ID="<subscription-id>" \
  --from-literal=ARM_TENANT_ID="<tenant-id>" \
  -n terraform-system
```

#### AWS (Optional)

```bash
kubectl create secret generic aws-credentials \
  --from-literal=AWS_ACCESS_KEY_ID="<access-key>" \
  --from-literal=AWS_SECRET_ACCESS_KEY="<secret-key>" \
  --from-literal=AWS_DEFAULT_REGION="eu-west-1" \
  -n terraform-system
```

### Customization Options

#### Enable/Disable Features

```yaml
# values.yaml
itl:
  enabled: true  # Enable ITL-specific configurations
  
monitoring:
  prometheus:
    enabled: true    # Enable ServiceMonitor
  grafana:
    enabled: true    # Enable Grafana dashboard

backup:
  enabled: true      # Enable automated backup
  schedule: "0 */6 * * *"  # Every 6 hours
  retention: "30d"   # Keep backups for 30 days

security:
  networkPolicies:
    enabled: true    # Enable network restrictions
  podSecurity:
    enabled: true    # Enable pod security standards
    standard: "restricted"
```

#### Organization Customization

```yaml
itl:
  organization:
    name: "Your Organization"
    domain: "yourdomain.com"
  environment:
    name: "production"  # or "staging", "development"
    region: "westeurope"
```

#### Module Registry Configuration

```yaml
itl:
  modules:
    registry:
      enabled: true
      url: "git::https://github.com/yourusername/terraform-modules.git"
    common:
      - name: "azure-vm"
        source: "git::https://github.com/yourusername/terraform-modules.git//azure-vm"
      - name: "kubernetes-cluster"
        source: "git::https://github.com/yourusername/terraform-modules.git//k8s-cluster"
    
    # Keycloak authentication modules with namespace flexibility
    keycloak:
      enabled: true
      server:
        url: "https://sts.itlusions.com"        # ITL STS endpoint
      realm:
        name: "ITL-Academy"                     # Default realm
      modules:
        server:
          source: "git::https://github.com/itlusions/terraform-modules.git//keycloak/server"
          version: "v1.0.0"
        realm:
          source: "git::https://github.com/itlusions/terraform-modules.git//keycloak/realm"
          version: "v1.0.0"
        client:
          source: "git::https://github.com/itlusions/terraform-modules.git//keycloak/client"
          version: "v1.0.0"
        identity-provider:
          source: "git::https://github.com/itlusions/terraform-modules.git//keycloak/identity-provider"
          version: "v1.0.0"
        theme:
          source: "git::https://github.com/itlusions/terraform-modules.git//keycloak/theme"
          version: "v1.0.0"
        backup:
          source: "git::https://github.com/itlusions/terraform-modules.git//keycloak/backup"
          version: "v1.0.0"
      
      # Example client configurations with namespace specification
      clients:
        - name: "student-portal"
          clientId: "student-portal-client"
          realm: "ITL-Academy"
          enabled: true
          # Deploy secrets to application namespace
          secretConfig:
            name: "keycloak-credentials"
            namespace: "student-portal"          # Application namespace
        
        - name: "partner-integration"
          clientId: "partner-client"
          realm: "Partners"                     # Different realm
          enabled: true
          secretConfig:
            name: "partner-keycloak-credentials"
            namespace: "partner-apps"           # Partner namespace
```

> **Note**: For detailed Keycloak module configuration and client creation, see:
> - [docs/KEYCLOAK_MODULES.md](docs/KEYCLOAK_MODULES.md) - Complete module documentation
> - [docs/CLIENT_CREATION_WALKTHROUGH.md](docs/CLIENT_CREATION_WALKTHROUGH.md) - Step-by-step client creation guide
    security:
      enabled: true
      requiredChecks:
        - "CKV_AZURE_1"  # Ensure no secrets in ARM templates
        - "CKV_AZURE_2"  # Ensure storage account access keys are secured
        - "CKV_K8S_8"   # Liveness Probe Should be Configured
```

## Usage

### Deployment Patterns

The ITL Terranetes controller supports multiple deployment patterns to accommodate different organizational needs:

#### Pattern 1: Centralized Configuration Management
All Terraform configurations managed in the `terraform-system` namespace:

```yaml
# Traditional approach - all configs in terraform-system
apiVersion: terraform.appvia.io/v1alpha1
kind: Configuration
metadata:
  name: itl-azure-vm
  namespace: terraform-system  # Centralized management
spec:
  module: git::https://github.com/itlusions/terraform-modules.git//azure-vm
  variables:
    vm_name: "itl-student-vm"
    resource_group: "itl-rg-students"
    location: "westeurope"
  writeConnectionSecretsToRef:
    name: vm-connection-details
    namespace: terraform-system  # Secrets in central namespace
```

#### Pattern 2: Application-Owned Configuration (Recommended)
Applications manage their own infrastructure configurations in their namespaces:

```yaml
# Application-owned approach - config in app namespace
apiVersion: terraform.appvia.io/v1alpha1
kind: Configuration
metadata:
  name: student-portal-infrastructure
  namespace: student-portal      # Application namespace
  labels:
    app.kubernetes.io/name: student-portal
    app.kubernetes.io/component: infrastructure
spec:
  module: git::https://github.com/itlusions/terraform-modules.git//web-app
  variables:
    app_name: "student-portal"
    namespace: "student-portal"
    environment: "production"
  writeConnectionSecretsToRef:
    name: infrastructure-secrets
    namespace: student-portal    # Secrets stay with application
```

#### Pattern 3: Helm Integration for Application Infrastructure
Include Terraform configurations in your application's Helm chart:

```yaml
# In your app's templates/terraform-config.yaml
{{- if .Values.infrastructure.enabled }}
apiVersion: terraform.appvia.io/v1alpha1
kind: Configuration
metadata:
  name: {{ include "myapp.fullname" . }}-infrastructure
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "myapp.labels" . | nindent 4 }}
    component: infrastructure
spec:
  module:
    source: {{ .Values.infrastructure.module.source | quote }}
    version: {{ .Values.infrastructure.module.version | quote }}
  variables:
    {{- range .Values.infrastructure.variables }}
    - key: {{ .key }}
      value: {{ .value | quote }}
    {{- end }}
    - key: app_name
      value: {{ include "myapp.name" . | quote }}
    - key: namespace
      value: {{ .Release.Namespace | quote }}
  writeConnectionSecretsToRef:
    name: {{ include "myapp.fullname" . }}-infrastructure
    namespace: {{ .Release.Namespace }}
{{- end }}
```

### 1. Create a Configuration

```yaml
apiVersion: terraform.appvia.io/v1alpha1
kind: Configuration
metadata:
  name: itl-azure-vm
  namespace: terraform-system
spec:
  module: git::https://github.com/itlusions/terraform-modules.git//azure-vm
  variables:
    vm_name: "itl-student-vm"
    resource_group: "itl-rg-students"
    location: "westeurope"
  writeConnectionSecretsToRef:
    name: vm-connection-details
```

### 2. Apply the Configuration

```bash
# For centralized management
kubectl apply -f configuration.yaml

# For application-owned configurations
kubectl apply -f configuration.yaml -n your-app-namespace

# Via Helm (recommended for applications)
helm install my-app ./my-app-chart -n my-app-namespace \
  --set infrastructure.enabled=true
```

### 3. Monitor Progress

```bash
# Check configuration status (any namespace)
kubectl get configurations -A
kubectl get configurations -n specific-namespace

# Check terraform runs
kubectl get runs -n terraform-system
kubectl get runs -A  # All namespaces

# View detailed status
kubectl describe configuration student-portal-infrastructure -n student-portal

# Check secrets in application namespace
kubectl get secrets -n student-portal -l component=infrastructure
```

### 4. Multi-Namespace Management

```bash
# View all configurations across namespaces
kubectl get configurations --all-namespaces -o wide

# Filter by application
kubectl get configurations -A -l app.kubernetes.io/name=student-portal

# Check controller's multi-namespace capability
kubectl logs -n terraform-system deployment/terranetes-controller | grep "watching namespace"
```

## Monitoring and Observability

### Prometheus Integration

The chart includes a ServiceMonitor that automatically configures Prometheus to scrape Terranetes metrics:

```yaml
# ServiceMonitor configuration
spec:
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
    metricRelabelings:
    - sourceLabels: [__name__]
      regex: 'terranetes_.*'
      action: keep
    - replacement: "ITL Academy"
      targetLabel: organization
    - replacement: "production"
      targetLabel: environment
```

### Available Metrics

Key metrics exposed by the controller:
- `terranetes_configurations_total` - Total number of configurations
- `terranetes_configurations_active` - Currently active configurations
- `terranetes_plans_total` - Total number of plans executed
- `terranetes_policy_violations_total` - Policy violations detected
- `terranetes_drift_detected_total` - Infrastructure drift events

### Grafana Dashboard

Pre-configured dashboard includes:
- Configuration status overview
- Policy compliance metrics
- Cost tracking and budget alerts
- Drift detection timeline
- Executor performance metrics

### Automated Backup

The backup CronJob performs:

```bash
# Backup script runs every 6 hours by default
- Terraform state files from all configurations
- Configuration manifests
- Policy results and compliance data
- Stores backups with 30-day retention
```

Backup locations:
- `/backup/terraform-states/` - State files
- `/backup/configurations/` - Configuration manifests
- `/backup/policies/` - Policy results

## Integration with ITL Infrastructure

### Keycloak Integration

This deployment integrates with ITL's existing Keycloak client management:

```yaml
itl:
  keycloak:
    enabled: true
    clientManagement:
      enabled: true
      secretName: "keycloak-client-secrets"
```

### ArgoCD Integration

Terranetes configurations can be managed through ArgoCD:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: itl-infrastructure
spec:
  source:
    repoURL: https://github.com/itlusions/infrastructure
    path: terraform/configurations
  destination:
    server: https://kubernetes.default.svc
    namespace: terraform-system
```

## Usage Examples

### Basic Configuration

Create a simple Terraform configuration for Azure resources:

```yaml
# Option 1: Centralized in terraform-system namespace
apiVersion: terraform.appvia.io/v1alpha1
kind: Configuration
metadata:
  name: azure-vm-example
  namespace: terraform-system
spec:
  module:
    source: "git::https://github.com/itlusions/terraform-modules//azure/virtual-machine"
    version: "v1.2.0"
  
  variables:
    - key: location
      value: "West Europe"
    - key: vm_size
      value: "Standard_B2s"
    - key: environment
      value: "production"
    - key: organization
      value: "ITL Academy"
  
  writeConnectionSecretsToRef:
    name: azure-vm-connection
    namespace: terraform-system
  
  providerConfigRef:
    name: azure-provider-config

---
# Option 2: Application-owned configuration (recommended)
apiVersion: terraform.appvia.io/v1alpha1
kind: Configuration
metadata:
  name: my-app-infrastructure
  namespace: my-app-namespace       # Application namespace
  labels:
    app.kubernetes.io/name: my-app
    app.kubernetes.io/component: infrastructure
spec:
  module:
    source: "git::https://github.com/itlusions/terraform-modules//azure/virtual-machine"
    version: "v1.2.0"
  
  variables:
    - key: location
      value: "West Europe"
    - key: vm_size
      value: "Standard_B2s"
    - key: app_name
      value: "my-app"
    - key: namespace
      value: "my-app-namespace"
  
  writeConnectionSecretsToRef:
    name: my-app-infrastructure
    namespace: my-app-namespace     # Secrets in app namespace
  
  providerConfigRef:
    name: azure-provider-config
```

### Configuration with Policies

Apply cost and security policies to your infrastructure:

```yaml
apiVersion: terraform.appvia.io/v1alpha1
kind: Configuration
metadata:
  name: secure-infrastructure
  namespace: terraform-system
spec:
  module:
    source: "git::https://github.com/itlusions/terraform-modules//azure/secure-webapp"
  
  # Cost control policy
  policy:
    - name: cost-control
      source:
        name: itl-cost-policies
        namespace: policy-system
      variables:
        max_monthly_cost: "500"
        budget_alerts: "true"
    
    # Security compliance
    - name: security-baseline
      source:
        name: itl-security-policies
        namespace: policy-system
      variables:
        enforce_encryption: "true"
        require_backup: "true"
        network_isolation: "strict"
  
  variables:
    - key: application_name
      value: "student-portal"
    - key: environment
      value: "production"
```

### Multi-Environment Setup

Deploy the same configuration across environments with application-owned approach:

```yaml
# Production environment in dedicated namespace
apiVersion: terraform.appvia.io/v1alpha1
kind: Configuration
metadata:
  name: webapp-infrastructure
  namespace: webapp-production      # Application production namespace
  labels:
    environment: production
    application: student-portal
    app.kubernetes.io/name: student-portal
spec:
  module:
    source: "git::https://github.com/itlusions/terraform-modules//azure/webapp"
  
  variables:
    - key: environment
      value: "production"
    - key: instance_count
      value: "3"
    - key: instance_size
      value: "Standard_P2v2"
    - key: app_name
      value: "student-portal"
    - key: namespace
      value: "webapp-production"
  
  writeConnectionSecretsToRef:
    name: webapp-infrastructure
    namespace: webapp-production    # Keep secrets in app namespace
  
  providerConfigRef:
    name: azure-production
---
# Staging environment in separate namespace
apiVersion: terraform.appvia.io/v1alpha1
kind: Configuration
metadata:
  name: webapp-infrastructure
  namespace: webapp-staging         # Application staging namespace
  labels:
    environment: staging
    application: student-portal
    app.kubernetes.io/name: student-portal
spec:
  module:
    source: "git::https://github.com/itlusions/terraform-modules//azure/webapp"
  
  variables:
    - key: environment
      value: "staging"
    - key: instance_count
      value: "1"
    - key: instance_size
      value: "Standard_B2s"
    - key: app_name
      value: "student-portal"
    - key: namespace
      value: "webapp-staging"
  
  writeConnectionSecretsToRef:
    name: webapp-infrastructure
    namespace: webapp-staging       # Keep secrets in app namespace
  
  providerConfigRef:
    name: azure-staging

---
# Keycloak client configuration with namespace-specific secrets
apiVersion: terraform.appvia.io/v1alpha1
kind: Configuration
metadata:
  name: keycloak-client-config
  namespace: webapp-production
  labels:
    app.kubernetes.io/name: student-portal
    app.kubernetes.io/component: authentication
spec:
  module:
    source: "git::https://github.com/itlusions/terraform-modules//keycloak/client"
    version: "v1.0.0"
  
  variables:
    - key: keycloak_url
      value: "https://sts.itlusions.com"
    - key: realm_name
      value: "ITL-Academy"
    - key: client_id
      value: "student-portal-client"
    - key: client_name
      value: "Student Portal"
    
    # Deploy secret to application namespace
    - key: secret_name
      value: "keycloak-credentials"
    - key: secret_namespace
      value: "webapp-production"     # Same as application namespace
  
  writeConnectionSecretsToRef:
    name: keycloak-client-secrets
    namespace: webapp-production    # Application can access directly
```

## Advanced Troubleshooting

### Common Issues

#### Configuration Not Applying

**Problem**: Configuration stuck in "Planning" state

**Solution**:
1. Check controller logs:
   ```bash
   kubectl logs -n terraform-system deployment/terranetes-controller-manager
   ```

2. Verify provider configuration:
   ```bash
   kubectl get providerconfig -n terraform-system
   kubectl describe providerconfig azure-provider-config
   ```

3. Check for policy violations:
   ```bash
   kubectl get policies -n terraform-system
   kubectl describe configuration your-config-name -n your-namespace
   ```

4. Verify namespace permissions (for application-owned configs):
   ```bash
   # Check if controller can access the application namespace
   kubectl auth can-i get configurations --namespace=my-app-namespace \
     --as=system:serviceaccount:terraform-system:terranetes-controller
   
   # Check if controller can create secrets in app namespace
   kubectl auth can-i create secrets --namespace=my-app-namespace \
     --as=system:serviceaccount:terraform-system:terranetes-controller
   ```

#### Provider Authentication Issues

**Problem**: "authentication failed" errors

**Solution**:
1. Verify provider secrets exist:
   ```bash
   kubectl get secrets -n terraform-system | grep provider
   ```

2. Check secret content:
   ```bash
   kubectl get secret azure-provider-secret -o yaml
   ```

3. Recreate provider configuration if needed:
   ```bash
   kubectl delete providerconfig azure-provider-config
   kubectl apply -f provider-config.yaml
   ```

#### State File Corruption

**Problem**: Terraform state is corrupted

**Solution**:
1. Check backup availability:
   ```bash
   kubectl get cronjobs -n terraform-system
   kubectl logs job/terranetes-backup-<timestamp>
   ```

2. Restore from backup:
   ```bash
   # Access backup pod
   kubectl exec -it backup-pod -- ls /backup/terraform-states/
   
   # Copy state file to configuration
   kubectl cp backup-pod:/backup/terraform-states/config-name.tfstate ./terraform.tfstate
   ```

3. Re-import resources if necessary:
   ```bash
   # Through Configuration annotation
   kubectl annotate configuration config-name terraform.appvia.io/import="resource_type.name:azure_resource_id"
   ```

### Performance Optimization

#### Reduce Plan Time

1. **Limit concurrent executions**:
   ```yaml
   spec:
     controller:
       executor:
         maxConcurrentExecutions: 5
   ```

2. **Use remote state backends**:
   ```yaml
   spec:
     backend:
       secretRef:
         name: terraform-backend-config
         namespace: terraform-system
   ```

3. **Configure appropriate resource limits**:
   ```yaml
   spec:
     executor:
       resources:
         limits:
           memory: "2Gi"
           cpu: "1000m"
         requests:
           memory: "1Gi"
           cpu: "500m"
   ```

#### Scale Controller

For high-load environments:

```bash
# Scale controller replicas
helm upgrade terranetes . \
  --set terranetes-controller.replicas=3 \
  --set terranetes-controller.controller.executor.maxConcurrentExecutions=10
```

### Debugging Commands

#### Check Configuration Status

```bash
# List all configurations across namespaces
kubectl get configurations -A

# List configurations in specific namespace
kubectl get configurations -n my-app-namespace

# Get detailed status for application-owned config
kubectl describe configuration my-app-infrastructure -n my-app-namespace

# View logs for specific namespace configs
kubectl logs -n terraform-system -l app=terranetes-controller --tail=100 | grep my-app-namespace
```

#### Monitor Resource Usage

```bash
# Check controller resource usage
kubectl top pods -n terraform-system

# View metrics
curl http://terranetes-controller:9090/metrics | grep terranetes_

# Check configurations by namespace
kubectl get configurations -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase
```

#### Multi-Namespace Debugging

```bash
# Verify controller watches all namespaces
kubectl logs -n terraform-system deployment/terranetes-controller | grep "watching namespace"

# Check RBAC permissions across namespaces
kubectl describe clusterrole terranetes-controller

# List secrets created by configurations across namespaces
kubectl get secrets -A -l terraform.appvia.io/configuration

# Check specific application's infrastructure secrets
kubectl get secrets -n my-app-namespace -l app.kubernetes.io/component=infrastructure
```

#### Policy Debugging

```bash
# Check policy status
kubectl get policies -n terraform-system

# View policy violations
kubectl get events --field-selector reason=PolicyViolation

# Test policy against configuration
kubectl apply --dry-run=server -f configuration.yaml
```

### Emergency Procedures

#### Controller Recovery

If the controller becomes unresponsive:

```bash
# Restart controller
kubectl rollout restart deployment/terranetes-controller-manager -n terraform-system

# Check controller health
kubectl get pods -n terraform-system -l app=terranetes-controller

# Verify metrics endpoint
kubectl port-forward -n terraform-system svc/terranetes-controller 9090:9090
curl http://localhost:9090/health

# Check if controller is watching all namespaces
kubectl logs -n terraform-system deployment/terranetes-controller | grep "started watching"
```

#### Backup Restoration

In case of catastrophic failure:

```bash
# List available backups
kubectl exec -it backup-pod -- ls -la /backup/

# Restore configurations (all namespaces)
kubectl apply -f /backup/configurations/

# Restore application-specific configurations
kubectl apply -f /backup/configurations/my-app-namespace/ -n my-app-namespace

# Restore state files (manual process)
# Contact ITL infrastructure team for state restoration procedures
```

#### Application-Owned Configuration Issues

```bash
# Verify application namespace exists
kubectl get namespace my-app-namespace

# Check if configuration exists in app namespace
kubectl get configuration -n my-app-namespace

# Verify secrets are created in correct namespace
kubectl get secrets -n my-app-namespace -l terraform.appvia.io/configuration

# Check controller permissions for app namespace
kubectl auth can-i create configurations --namespace=my-app-namespace \
  --as=system:serviceaccount:terraform-system:terranetes-controller

# Troubleshoot Helm integration
helm get values my-app -n my-app-namespace
helm template my-app ./my-app-chart --set infrastructure.enabled=true
```

## Support and Documentation

### Additional Resources

- **Terranetes Documentation**: https://docs.terranetes.appvia.io/
- **ITL Terraform Modules**: https://github.com/itlusions/terraform-modules
- **Keycloak Integration**:
  - [docs/KEYCLOAK_MODULES.md](docs/KEYCLOAK_MODULES.md) - Complete module documentation
  - [docs/CLIENT_CREATION_WALKTHROUGH.md](docs/CLIENT_CREATION_WALKTHROUGH.md) - Step-by-step client creation guide
- **Multi-Namespace Configuration**: See [Application-Owned Configuration Patterns](#pattern-2-application-owned-configuration-recommended) above
- **Policy Examples**: https://github.com/itlusions/terranetes-policies
- **Troubleshooting Guide**: https://wiki.itlusions.com/infrastructure/terranetes

### Best Practices

#### Application-Owned Infrastructure
1. **Keep configurations in application namespaces** for better isolation
2. **Use Helm charts** to manage both application and infrastructure together
3. **Deploy secrets to application namespaces** for direct access
4. **Use consistent labeling** for easy identification and management

#### Namespace Management
1. **Controller Sharing**: One controller manages configurations across all namespaces
2. **Secret Isolation**: Keep infrastructure secrets in application namespaces
3. **RBAC**: Ensure proper permissions for cross-namespace operations
4. **Monitoring**: Use namespace labels for organized monitoring

### Getting Help

1. **Check the ITL Wiki**: Common solutions are documented
2. **Review Controller Logs**: Most issues are visible in logs
3. **Contact Infrastructure Team**: Use #infrastructure Slack channel
4. **Create GitHub Issue**: For bugs or feature requests

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Adding new policies
- Contributing to Terraform modules
- Reporting security issues
- Code standards and review process