{{/*
Expand the name of the chart.
*/}}
{{- define "vsphere-csi.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "vsphere-csi.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "vsphere-csi.labels" -}}
helm.sh/chart: {{ include "vsphere-csi.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Namespace helper
*/}}
{{- define "vsphere-csi.namespace" -}}
{{- .Values.namespace | default .Release.Namespace }}
{{- end }}
