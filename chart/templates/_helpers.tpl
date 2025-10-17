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