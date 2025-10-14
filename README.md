-# ITL Terranetes Controller

This Helm chart deploys the Terranetes Controller for ITL Academy, providing infrastructure-as-code capabilities with GitOps workflows, policy enforcement, and cost management.

## Overview

Terranetes is a Kubernetes-native solution that enables teams to provision and manage cloud infrastructure using Terraform in a GitOps manner. This ITL-specific deployment includes:

- **Self-Service Infrastructure**: Teams can provision cloud resources through Kubernetes CRDs
- **Policy Enforcement**: Security and compliance policies using Checkov
- **Cost Management**: Cost estimation and budget controls
- **GitOps Integration**: Native integration with ArgoCD and Flux
- **Approval Workflows**: Multi-stage approval processes for production changes
- **Drift Detection**: Automatic detection and alerting of infrastructure drift

## Prerequisites

1. **Kubernetes Cluster**: Version 1.24+
2. **Helm**: Version 3.8+
3. **Cloud Credentials**: Appropriate cloud provider credentials stored as Kubernetes secrets
4. **ArgoCD** (optional): For GitOps workflow integration
5. **Prometheus** (optional): For monitoring and alerting

## Installation

### 1. Add the Official Terranetes Helm Repository

```bash
helm repo add appvia https://terranetes-controller.appvia.io
helm repo update
```

### 2. Install ITL Terranetes Controller

```bash
# Create the terraform-system namespace
kubectl create namespace terraform-system

# Install with ITL-specific configuration
helm install itl-terranetes . -n terraform-system
```

### 3. Verify Installation

```bash
# Check controller deployment
kubectl get pods -n terraform-system

# Check CRDs
kubectl get crd | grep terranetes

# Check controller logs
kubectl logs -n terraform-system deployment/terranetes-controller
```

## Configuration

### Default Configuration

The chart includes ITL-specific defaults:

- **Namespace**: `terraform-system`
- **Replicas**: 2 (for high availability)
- **Security**: Enhanced security policies enabled
- **Integration**: Pre-configured for ITL's ArgoCD, Grafana, and Keycloak

### Cloud Provider Setup

#### Azure (Recommended for ITL)

```bash
# Create Azure service principal
az ad sp create-for-rbac --name "terranetes-sp" --role "Contributor"

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

### Policy Configuration

ITL includes security policies for educational environments:

```yaml
itl:
  policies:
    security:
      enabled: true
      requiredChecks:
        - "CKV_AZURE_1"  # Ensure no secrets in ARM templates
        - "CKV_AZURE_2"  # Ensure storage account access keys are secured
        - "CKV_K8S_8"   # Liveness Probe Should be Configured
```

## Usage

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
kubectl apply -f configuration.yaml
```

### 3. Monitor Progress

```bash
# Check configuration status
kubectl get configurations -n terraform-system

# Check terraform runs
kubectl get runs -n terraform-system

# View detailed status
kubectl describe configuration itl-azure-vm -n terraform-system
```

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

### Monitoring Integration

Metrics and alerts are integrated with ITL's Prometheus/Grafana stack:

- **Metrics**: Available at `http://terranetes-controller:9090/metrics`
- **Dashboards**: Pre-configured Grafana dashboards for infrastructure monitoring
- **Alerts**: Cost and drift detection alerts

## Common Use Cases

### 1. Student Environment Provisioning

```yaml
apiVersion: terraform.appvia.io/v1alpha1
kind: Configuration
metadata:
  name: student-environment
spec:
  module: git::https://github.com/itlusions/terraform-modules.git//student-env
  variables:
    student_id: "student-001"
    course: "kubernetes-advanced"
    expires_at: "2024-12-31"
```

### 2. Development Team Resources

```yaml
apiVersion: terraform.appvia.io/v1alpha1
kind: Configuration
metadata:
  name: dev-team-resources
spec:
  module: git::https://github.com/itlusions/terraform-modules.git//dev-environment
  variables:
    team_name: "backend-team"
    environment: "development"
```

### 3. Production Infrastructure

```yaml
apiVersion: terraform.appvia.io/v1alpha1
kind: Configuration
metadata:
  name: production-infra
spec:
  module: git::https://github.com/itlusions/terraform-modules.git//production-setup
  variables:
    environment: "production"
    high_availability: true
  writeConnectionSecretsToRef:
    name: prod-secrets
```

## Security Considerations

### 1. Network Policies

Network policies are enabled by default to restrict controller access:

```yaml
terranetes-controller:
  networkPolicy:
    enabled: true
```

### 2. Pod Security Standards

The deployment uses restricted pod security standards:

```yaml
security:
  podSecurity:
    enabled: true
    standard: "restricted"
```

### 3. Image Scanning

Container images are scanned for vulnerabilities:

```yaml
security:
  imageScanning:
    enabled: true
```

## Troubleshooting

### Controller Not Starting

```bash
# Check pod status
kubectl get pods -n terraform-system

# Check events
kubectl get events -n terraform-system --sort-by='.lastTimestamp'

# Check controller logs
kubectl logs -n terraform-system deployment/terranetes-controller
```

### Configuration Stuck in Pending

```bash
# Check configuration status
kubectl describe configuration <name> -n terraform-system

# Check runs
kubectl get runs -n terraform-system

# Check executor logs
kubectl logs -n terraform-system -l app.kubernetes.io/component=executor
```

### Policy Failures

```bash
# Check policy results
kubectl get configurations -o wide

# View policy details
kubectl describe configuration <name> -n terraform-system
```

## Maintenance

### Upgrading

```bash
# Update Helm repositories
helm repo update

# Upgrade ITL Terranetes
helm upgrade itl-terranetes . -n terraform-system
```

### Backup

The chart includes automatic backup of Terraform state:

```yaml
backup:
  enabled: true
  schedule: "0 */6 * * *"  # Every 6 hours
  retention: "30d"
```

### Monitoring

Key metrics to monitor:

- **Configuration Success Rate**: Percentage of successful terraform applies
- **Policy Compliance**: Percentage of configurations passing policy checks
- **Cost Trends**: Monthly infrastructure costs
- **Drift Detection**: Number of configurations with detected drift

## Support

For support with ITL Terranetes deployment:

1. **Documentation**: Check the [official Terranetes documentation](https://terranetes.appvia.io/)
2. **ITL Issues**: Contact ITL DevOps team for deployment-specific issues
3. **Community**: Join the [Terranetes Slack community](https://appvia.slack.com/)

## Contributing

To contribute to ITL's Terranetes configuration:

1. Fork the ITL.Terranetes repository
2. Create a feature branch
3. Submit a pull request with detailed description
4. Ensure all tests pass and documentation is updated

## License

This ITL-specific configuration is licensed under the same terms as the official Terranetes controller. See the [LICENSE](LICENSE) file for details.