{{/*
Expand the name of the chart.
*/}}
{{- define "itl-terranetes.name" }}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "itl-terranetes.fullname" }}
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
Common labels
*/}}
{{- define "itl-terranetes.labels" }}
helm.sh/chart: {{ include "itl-terranetes.chart" . }}
{{ include "itl-terranetes.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Chart name and version as used by the chart label.
*/}}
{{- define "itl-terranetes.chart" }}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "itl-terranetes.selectorLabels" }}
app.kubernetes.io/name: {{ include "itl-terranetes.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ITL-specific labels
*/}}
{{- define "itl-terranetes.itlLabels" }}
{{- if .Values.itl }}
{{- if .Values.itl.project }}
itl.academy/project: {{ .Values.itl.project.name | default "terranetes" | quote }}
{{- else }}
itl.academy/project: "terranetes"
{{- end }}
{{- if .Values.itl.environment }}
itl.academy/environment: {{ .Values.itl.environment.name | default "production" | quote }}
{{- else }}
itl.academy/environment: "production"  
{{- end }}
itl.academy/version: {{ .Values.itl.version | default .Chart.AppVersion | quote }}
{{- else }}
itl.academy/project: "terranetes"
itl.academy/environment: "production"
itl.academy/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- end }}

{{/*
ITL-specific annotations  
*/}}
{{- define "itl-terranetes.itlAnnotations" }}
itl.academy/deployment-date: {{ now | date "2006-01-02T15:04:05Z07:00" | quote }}
itl.academy/managed-by: "ITL Academy Platform Team"
{{- if and .Values.itl .Values.itl.documentation .Values.itl.documentation.url }}
itl.academy/documentation: {{ .Values.itl.documentation.url | quote }}
{{- end }}
{{- end }}

{{/*
Generate Keycloak clients YAML configuration
*/}}
{{- define "keycloak.clientsYaml" }}
{{- if .Values.itl.keycloak.clients }}
clients:
{{- range .Values.itl.keycloak.clients }}
  - clientId: {{ .clientId | quote }}
    name: {{ .name | quote }}
    {{- if .description }}
    description: {{ .description | quote }}
    {{- end }}
    enabled: {{ .enabled | default true }}
    clientAuthenticatorType: {{ .clientAuthenticatorType | default "client-secret" | quote }}
    {{- if .redirectUris }}
    redirectUris:
    {{- range .redirectUris }}
    - {{ . | quote }}
    {{- end }}
    {{- end }}
    {{- if .webOrigins }}
    webOrigins:
    {{- range .webOrigins }}
    - {{ . | quote }}
    {{- end }}
    {{- end }}
    protocol: {{ .protocol | default "openid-connect" | quote }}
    publicClient: {{ .publicClient | default false }}
    standardFlowEnabled: {{ .standardFlowEnabled | default true }}
    directAccessGrantsEnabled: {{ .directAccessGrantsEnabled | default false }}
    serviceAccountsEnabled: {{ .serviceAccountsEnabled | default false }}
    {{- if .attributes }}
    attributes:
{{ toYaml .attributes | indent 6 }}
    {{- end }}
{{- end }}
{{- else }}
clients: []
{{- end }}
{{- end }}

{{/*
Generate Keycloak groups YAML configuration  
*/}}
{{- define "keycloak.groupsYaml" }}
{{- if .Values.itl.keycloak.groups }}
groups:
{{- range .Values.itl.keycloak.groups }}
  - name: {{ .name | quote }}
    {{- if .description }}
    description: {{ .description | quote }}
    {{- end }}
    {{- if .attributes }}
    attributes:
{{ toYaml .attributes | indent 6 }}
    {{- end }}
    {{- if .subGroups }}
    subGroups:
{{ toYaml .subGroups | indent 6 }}
    {{- end }}
{{- end }}
{{- else }}
groups: []
{{- end }}
{{- end }}

{{/*
Generate policy configuration
*/}}
{{- define "itl-terranetes.policyConfig" }}
{{- if .Values.itl.policies }}
enabled: {{ .Values.itl.policies.enabled | default true }}
{{- if .Values.itl.policies.source }}
source: {{ .Values.itl.policies.source | quote }}
{{- end }}
{{- if .Values.itl.policies.rules }}
rules:
{{- range .Values.itl.policies.rules }}
  - name: {{ .name | quote }}
    severity: {{ .severity | default "warning" | quote }}
    {{- if .description }}
    description: {{ .description | quote }}
    {{- end }}
{{- end }}
{{- end }}
{{- else }}
enabled: false
{{- end }}
{{- end }}

{{/*
Generate module registry configuration
*/}}
{{- define "itl-terranetes.moduleRegistry" }}
{{- if .Values.itl.modules }}
enabled: {{ .Values.itl.modules.registry.enabled | default true }}
{{- if .Values.itl.modules.registry.url }}
url: {{ .Values.itl.modules.registry.url | quote }}
{{- end }}
{{- if .Values.itl.modules.common }}
common:
{{- range .Values.itl.modules.common }}
  - name: {{ .name | quote }}
    source: {{ .source | quote }}
    {{- if .version }}
    version: {{ .version | quote }}
    {{- end }}
{{- end }}
{{- end }}
{{- else }}
enabled: false
{{- end }}
{{- end }}

{{/*
Generate contexts configuration
*/}}
{{- define "itl-terranetes.contexts" }}
{{- if .Values.itl.contexts }}
{{- if .Values.itl.contexts.development }}
development:
  enabled: {{ .Values.itl.contexts.development.enabled | default false }}
  {{- if .Values.itl.contexts.development.namespace }}
  namespace: {{ .Values.itl.contexts.development.namespace | quote }}
  {{- end }}
{{- end }}
{{- if .Values.itl.contexts.production }}
production:
  enabled: {{ .Values.itl.contexts.production.enabled | default false }}
  {{- if .Values.itl.contexts.production.namespace }}
  namespace: {{ .Values.itl.contexts.production.namespace | quote }}
  {{- end }}
{{- end }}
{{- else }}
development:
  enabled: false
production:
  enabled: false
{{- end }}
{{- end }}

{{/*
Generate integrations configuration
*/}}
{{- define "itl-terranetes.integrations" }}
{{- if .Values.integrations }}
{{- if .Values.integrations.argocd }}
argocd:
  enabled: {{ .Values.integrations.argocd.enabled | default false }}
  {{- if .Values.integrations.argocd.namespace }}
  namespace: {{ .Values.integrations.argocd.namespace | quote }}
  {{- end }}
{{- end }}
{{- if .Values.integrations.grafana }}
grafana:
  enabled: {{ .Values.integrations.grafana.enabled | default false }}
  {{- if .Values.integrations.grafana.namespace }}
  namespace: {{ .Values.integrations.grafana.namespace | quote }}
  {{- end }}
{{- end }}
{{- if .Values.integrations.prometheus }}
prometheus:
  enabled: {{ .Values.integrations.prometheus.enabled | default false }}
  {{- if .Values.integrations.prometheus.namespace }}
  namespace: {{ .Values.integrations.prometheus.namespace | quote }}
  {{- end }}
{{- end }}
{{- if .Values.integrations.keycloak }}
keycloak:
  enabled: {{ .Values.integrations.keycloak.enabled | default false }}
  {{- if .Values.integrations.keycloak.url }}
  url: {{ .Values.integrations.keycloak.url | quote }}
  {{- end }}
{{- end }}
{{- else }}
argocd:
  enabled: false
grafana:
  enabled: false
prometheus:
  enabled: false
keycloak:
  enabled: false
{{- end }}
{{- end }}