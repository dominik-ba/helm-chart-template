
{{- define "template.pod" -}}
{{- if .Values.schedulerName }}
schedulerName: "{{ .Values.schedulerName }}"
{{- end }}
serviceAccountName: {{ template "template.serviceAccountName" . }}
automountServiceAccountToken: {{ .Values.serviceAccount.autoMount }}
{{- if .Values.securityContext }}
securityContext:
{{ toYaml .Values.securityContext | indent 2 }}
{{- end }}
{{- if .Values.hostAliases }}
hostAliases:
{{ toYaml .Values.hostAliases | indent 2 }}
{{- end }}
{{- if .Values.priorityClassName }}
priorityClassName: {{ .Values.priorityClassName }}
{{- end }}
{{- if ( or .Values.persistence.enabled .Values.extraInitContainers) }}
initContainers:
{{- end }}
{{- if ( and .Values.persistence.enabled .Values.initChownData.enabled ) }}
  - name: init-chown-data
    {{- if .Values.initChownData.image.sha }}
    image: "{{ .Values.initChownData.image.repository }}:{{ .Values.initChownData.image.tag }}@sha256:{{ .Values.initChownData.image.sha }}"
    {{- else }}
    image: "{{ .Values.initChownData.image.repository }}:{{ .Values.initChownData.image.tag }}"
    {{- end }}
    imagePullPolicy: {{ .Values.initChownData.image.pullPolicy }}
    securityContext:
      runAsNonRoot: false
      runAsUser: 0
    command: ["chown", "-R", "{{ .Values.securityContext.runAsUser }}:{{ .Values.securityContext.runAsGroup }}", "/var/lib/template"]
    resources:
{{ toYaml .Values.initChownData.resources | indent 6 }}
    volumeMounts:
      - name: storage
        mountPath: "/var/lib/template"
{{- if .Values.persistence.subPath }}
        subPath: {{ tpl .Values.persistence.subPath . }}
{{- end }}
{{- end }}
{{- if .Values.extraInitContainers }}
{{ tpl (toYaml .Values.extraInitContainers) . | indent 2 }}
{{- end }}
{{- if .Values.image.pullSecrets }}
imagePullSecrets:
{{- $root := . }}
{{- range .Values.image.pullSecrets }}
  - name: {{ tpl . $root }}
{{- end}}
{{- end }}
{{- if not .Values.enableKubeBackwardCompatibility }}
enableServiceLinks: {{ .Values.enableServiceLinks }}
{{- end }}
containers:
  - name: {{ .Chart.Name }}
    {{- if .Values.image.sha }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}@sha256:{{ .Values.image.sha }}"
    {{- else }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
    {{- end }}
    imagePullPolicy: {{ .Values.image.pullPolicy }}
  {{- if .Values.command }}
    command:
    {{- range .Values.command }}
      - {{ . }}
    {{- end }}
  {{- end}}
{{- if .Values.containerSecurityContext }}
    securityContext:
{{- toYaml .Values.containerSecurityContext | nindent 6 }}
{{- end }}
    volumeMounts:
      {{- $root := . }}
      {{- range .Values.extraConfigmapMounts }}
      - name: {{ tpl .name $root }}
        mountPath: {{ tpl .mountPath $root }}
        subPath: {{ (tpl .subPath $root) | default "" }}
        readOnly: {{ .readOnly }}
      {{- end }}
    {{- range .Values.extraSecretMounts }}
      - name: {{ .name }}
        mountPath: {{ .mountPath }}
        readOnly: {{ .readOnly }}
        subPath: {{ .subPath | default "" }}
    {{- end }}
    {{- range .Values.extraVolumeMounts }}
      - name: {{ .name }}
        mountPath: {{ .mountPath }}
        subPath: {{ .subPath | default "" }}
        readOnly: {{ .readOnly }}
    {{- end }}
    {{- range .Values.extraEmptyDirMounts }}
      - name: {{ .name }}
        mountPath: {{ .mountPath }}
    {{- end }}
    ports:
      - name: {{ .Values.service.portName }}
        containerPort: {{ .Values.service.port }}
        protocol: TCP
      - name: {{ .Values.podPortName }}
        containerPort: 8080
        protocol: TCP
    env:
    {{- range $key, $value := .Values.env }}
      - name: "{{ tpl $key $ }}"
        value: "{{ tpl (print $value) $ }}"
    {{- end }}
    {{- range $key, $value := .Values.envValueFrom }}
      - name: {{ $key | quote }}
        valueFrom:
{{ tpl (toYaml $value) $ | indent 10 }}
    {{- end }}
    {{- if or .Values.envFromSecret .Values.envFromConfigMaps .Values.envFromSecrets }}
    envFrom:
    {{- if .Values.envFromSecret }}
      - secretRef:
          name: {{ tpl .Values.envFromSecret . }}
    {{- end }}
    {{- range .Values.envFromSecrets }}
      - secretRef:
          name: {{ tpl .name $ }}
          optional: {{ .optional | default false }}
    {{- end }}
    {{- range .Values.envFromConfigMaps }}
      - configMapRef:
          name: {{ tpl .name $ }}
          optional: {{ .optional | default false }}
    {{- end }}
    {{- end }}
    livenessProbe:
{{ toYaml .Values.livenessProbe | indent 6 }}
    readinessProbe:
{{ toYaml .Values.readinessProbe | indent 6 }}
{{- if .Values.lifecycleHooks }}
    lifecycle: {{ tpl (.Values.lifecycleHooks | toYaml) . | nindent 6 }}
{{- end }}
    resources:
{{ toYaml .Values.resources | indent 6 }}
{{- with .Values.extraContainers }}
{{ tpl . $ | indent 2 }}
{{- end }}
{{- with .Values.nodeSelector }}
nodeSelector:
{{ toYaml . | indent 2 }}
{{- end }}
{{- $root := . }}
{{- with .Values.affinity }}
affinity:
{{ tpl (toYaml .) $root | indent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
{{ toYaml . | indent 2 }}
{{- end }}
volumes:
  - name: config
    configMap:
      name: {{ template "template.fullname" . }}
{{- $root := . }}
{{- range .Values.extraConfigmapMounts }}
  - name: {{ tpl .name $root }}
    configMap:
      name: {{ tpl .configMap $root }}
{{- end }}
{{- if and .Values.persistence.enabled (eq .Values.persistence.type "pvc") }}
  - name: storage
    persistentVolumeClaim:
      claimName: {{ tpl (.Values.persistence.existingClaim | default (include "template.fullname" .)) . }}
{{- else if and .Values.persistence.enabled (eq .Values.persistence.type "statefulset") }}
# nothing
{{- else }}
  - name: storage
{{- if .Values.persistence.inMemory.enabled }}
    emptyDir:
      medium: Memory
{{- if .Values.persistence.inMemory.sizeLimit }}
      sizeLimit: {{ .Values.persistence.inMemory.sizeLimit }}
{{- end -}}
{{- else }}
    emptyDir: {}
{{- end -}}
{{- end -}}
{{- range .Values.extraSecretMounts }}
{{- if .secretName }}
  - name: {{ .name }}
    secret:
      secretName: {{ .secretName }}
      defaultMode: {{ .defaultMode }}
{{- else if .projected }}
  - name: {{ .name }}
    projected: {{- toYaml .projected | nindent 6 }}
{{- else if .csi }}
  - name: {{ .name }}
    csi: {{- toYaml .csi | nindent 6 }}
{{- end }}
{{- end }}
{{- range .Values.extraVolumeMounts }}
  - name: {{ .name }}
    {{- if .existingClaim }}
    persistentVolumeClaim:
      claimName: {{ .existingClaim }}
    {{- else if .hostPath }}
    hostPath:
      path: {{ .hostPath }}
    {{- else }}
    emptyDir: {}
    {{- end }}
{{- end }}
{{- range .Values.extraEmptyDirMounts }}
  - name: {{ .name }}
    emptyDir: {}
{{- end -}}
{{- if .Values.extraContainerVolumes }}
{{ toYaml .Values.extraContainerVolumes | indent 2 }}
{{- end }}
{{- end }}
