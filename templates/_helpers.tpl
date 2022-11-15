{{- define "workbench.hostname" -}}
{{- if .Values.hostname -}}
{{- .Values.hostname  -}}
{{- else -}}
kubernetes.docker.internal
{{- end -}}
{{- end -}}

