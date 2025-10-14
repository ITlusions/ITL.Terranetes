{{/*
Expand the name of the chart.
*/}}
{{- define "itl-terranetes.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "itl-terranetes.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "itl-terranetes.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Keycloak helper functions
*/}}

{{/*
Get Keycloak module by name
*/}}
{{- define "keycloak.getModule" -}}
{{- $name := .name -}}
{{- $modules := .context.Values.itl.modules.keycloak.modules -}}
{{- range $modules -}}
{{- if eq .name $name -}}
{{- . | toYaml -}}
{{- break -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Generate Keycloak client configuration as YAML
*/}}
{{- define "keycloak.clientsYaml" -}}
{{- if .Values.itl.keycloak.clients -}}
{{- range .Values.itl.keycloak.clients -}}
- name: {{ .name | quote }}
  clientId: {{ .clientId | quote }}
  enabled: {{ .enabled | default true }}
  protocol: {{ .protocol | default "openid-connect" | quote }}
  publicClient: {{ .publicClient | default false }}
  standardFlowEnabled: {{ .standardFlowEnabled | default true }}
  {{- if hasKey . "directAccessGrantsEnabled" }}
  directAccessGrantsEnabled: {{ .directAccessGrantsEnabled }}
  {{- end }}
  {{- if hasKey . "serviceAccountsEnabled" }}
  serviceAccountsEnabled: {{ .serviceAccountsEnabled }}
  {{- end }}
  {{- if .redirectUris }}
  redirectUris:
    {{- range .redirectUris }}
    - {{ . | quote }}
    {{- end }}
  {{- end }}
  {{- if .roles }}
  roles:
    {{- range .roles }}
    - {{ . | quote }}
    {{- end }}
  {{- end }}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Generate Keycloak groups configuration as YAML
*/}}
{{- define "keycloak.groupsYaml" -}}
{{- if .Values.itl.keycloak.groups -}}
{{- range .Values.itl.keycloak.groups -}}
- name: {{ .name | quote }}
  displayName: {{ .displayName | quote }}
  {{- if .description }}
  description: {{ .description | quote }}
  {{- end }}
  {{- if .realmRoles }}
  realmRoles:
    {{- range .realmRoles }}
    - {{ . | quote }}
    {{- end }}
  {{- end }}
  {{- if .clientRoles }}
  clientRoles:
    {{- range $client, $roles := .clientRoles }}
    {{ $client }}:
      {{- range $roles }}
      - {{ . | quote }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Check if Keycloak module exists and is enabled
*/}}
{{- define "keycloak.moduleEnabled" -}}
{{- $name := . -}}
{{- $enabled := false -}}
{{- range $.Values.itl.modules.keycloak.modules -}}
{{- if and (eq .name $name) (.enabled | default true) -}}
{{- $enabled = true -}}
{{- break -}}
{{- end -}}
{{- end -}}
{{- $enabled -}}
{{- end -}}

{{/*
Generate Keycloak environment variables for Terraform modules
*/}}
{{- define "keycloak.envVars" -}}
{{- if .Values.itl.keycloak.server.adminCredentials }}
- name: KEYCLOAK_ADMIN_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ .Values.itl.keycloak.server.adminCredentials.secretName }}
      key: {{ .Values.itl.keycloak.server.adminCredentials.usernameKey | default "username" }}
- name: KEYCLOAK_ADMIN_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.itl.keycloak.server.adminCredentials.secretName }}
      key: {{ .Values.itl.keycloak.server.adminCredentials.passwordKey | default "password" }}
{{- end }}
{{- if and .Values.itl.keycloak.identityProviders.azureAD.enabled }}
- name: AZURE_AD_CLIENT_ID
  valueFrom:
    secretKeyRef:
      name: azure-ad-credentials
      key: client-id
- name: AZURE_AD_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: azure-ad-credentials
      key: client-secret
- name: AZURE_AD_TENANT_ID
  valueFrom:
    secretKeyRef:
      name: azure-ad-credentials
      key: tenant-id
{{- end }}
{{- if and .Values.itl.keycloak.identityProviders.github.enabled }}
- name: GITHUB_CLIENT_ID
  valueFrom:
    secretKeyRef:
      name: github-oauth-credentials
      key: client-id
- name: GITHUB_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: github-oauth-credentials
      key: client-secret
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "itl-terranetes.labels" -}}
helm.sh/chart: {{ include "itl-terranetes.chart" . }}
{{ include "itl-terranetes.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: itl-infrastructure
{{- end }}

{{/*
Selector labels
*/}}
{{- define "itl-terranetes.selectorLabels" -}}
app.kubernetes.io/name: {{ include "itl-terranetes.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "itl-terranetes.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "itl-terranetes.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
ITL specific labels
*/}}
{{- define "itl-terranetes.itlLabels" -}}
itl.academy/organization: {{ .Values.itl.organization.name | default "ITL Academy" | quote }}
itl.academy/environment: {{ .Values.itl.environment.name | default "production" | quote }}
itl.academy/region: {{ .Values.itl.environment.region | default "westeurope" | quote }}
itl.academy/managed-by: "terranetes"
{{- end }}

{{/*
ITL specific annotations
*/}}
{{- define "itl-terranetes.itlAnnotations" -}}
itl.academy/contact: "devops@itl-academy.com"
itl.academy/documentation: "https://github.com/ITL-Academy/ITL.Terranetes"
itl.academy/monitoring: "https://grafana.itl-academy.com"
{{- end }}

{{/*
Generate cloud provider credentials secret name
*/}}
{{- define "itl-terranetes.azureSecretName" -}}
{{- if .Values.itl.providers.azure.enabled }}
{{- .Values.itl.providers.azure.secretName | default "azure-credentials" }}
{{- end }}
{{- end }}

{{- define "itl-terranetes.awsSecretName" -}}
{{- if .Values.itl.providers.aws.enabled }}
{{- .Values.itl.providers.aws.secretName | default "aws-credentials" }}
{{- end }}
{{- end }}

{{- define "itl-terranetes.gcpSecretName" -}}
{{- if .Values.itl.providers.google.enabled }}
{{- .Values.itl.providers.google.secretName | default "gcp-credentials" }}
{{- end }}
{{- end }}

{{/*
Generate policy configuration
*/}}
{{- define "itl-terranetes.policyConfig" -}}
{{- if .Values.itl.policies.security.enabled }}
checkov:
  enabled: true
  required_checks:
    {{- range .Values.itl.policies.security.requiredChecks }}
    - {{ . | quote }}
    {{- end }}
{{- end }}
{{- if .Values.itl.policies.cost.enabled }}
cost:
  enabled: true
  max_monthly_cost: {{ .Values.itl.policies.cost.maxMonthlyCost | default 1000 }}
{{- end }}
{{- if .Values.itl.policies.compliance.enabled }}
compliance:
  enabled: true
  standards:
    {{- range .Values.itl.policies.compliance.standards }}
    - {{ . | quote }}
    {{- end }}
{{- end }}
{{- end }}

{{/*
Generate module registry configuration
*/}}
{{- define "itl-terranetes.moduleRegistry" -}}
{{- if .Values.itl.modules.registry.enabled }}
registry:
  url: {{ .Values.itl.modules.registry.url | quote }}
  type: "git"
modules:
  {{- range .Values.itl.modules.common }}
  - name: {{ .name | quote }}
    source: {{ .source | quote }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Generate context configuration
*/}}
{{- define "itl-terranetes.contexts" -}}
{{- if .Values.itl.contexts.development.enabled }}
development:
  {{- toYaml .Values.itl.contexts.development.values | nindent 2 }}
{{- end }}
{{- if .Values.itl.contexts.production.enabled }}
production:
  {{- toYaml .Values.itl.contexts.production.values | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Generate integration configuration
*/}}
{{- define "itl-terranetes.integrations" -}}
{{- if .Values.integrations.argocd.enabled }}
argocd:
  enabled: true
  namespace: {{ .Values.integrations.argocd.namespace | quote }}
{{- end }}
{{- if .Values.integrations.grafana.enabled }}
grafana:
  enabled: true
  namespace: {{ .Values.integrations.grafana.namespace | quote }}
{{- end }}
{{- if .Values.integrations.prometheus.enabled }}
prometheus:
  enabled: true
  namespace: {{ .Values.integrations.prometheus.namespace | quote }}
{{- end }}
{{- if .Values.integrations.keycloak.enabled }}
keycloak:
  enabled: true
  namespace: {{ .Values.integrations.keycloak.namespace | quote }}
{{- end }}
{{- end }}

{{/*
Generate executor secrets list
*/}}
{{- define "itl-terranetes.executorSecrets" -}}
{{- $secrets := list }}
{{- if .Values.itl.providers.azure.enabled }}
{{- $secrets = append $secrets (include "itl-terranetes.azureSecretName" .) }}
{{- end }}
{{- if .Values.itl.providers.aws.enabled }}
{{- $secrets = append $secrets (include "itl-terranetes.awsSecretName" .) }}
{{- end }}
{{- if .Values.itl.providers.google.enabled }}
{{- $secrets = append $secrets (include "itl-terranetes.gcpSecretName" .) }}
{{- end }}
{{- if .Values.itl.keycloak.enabled }}
{{- if .Values.itl.keycloak.clientManagement.enabled }}
{{- $secrets = append $secrets .Values.itl.keycloak.clientManagement.secretName }}
{{- end }}
{{- end }}
{{- range .Values.terranetes-controller.controller.executorSecrets }}
{{- $secrets = append $secrets . }}
{{- end }}
{{- toYaml $secrets }}
{{- end }}