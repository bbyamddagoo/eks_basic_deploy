#!/bin/bash
##################################################################
# Kubernetes Basic Deploy Script
##################################################################
# MAINTAINER - Hyunbae HAN
# 2019.10.24 - Version 1.0
##################################################################

export CLUSTER_NAME="eks.bbyamddagoo.shop"
export AWS_EKS_CLUSTER_NAME="hbhan-eks-cluster-1"

export CLUSTER_NAME_MODI=`echo $CLUSTER_NAME | sed "s/\./\-/g"`

aws eks --region ap-northeast-2 update-kubeconfig --name $AWS_EKS_CLUSTER_NAME

################################################################################
# Cert-Manager FOR Install EKS ALB Ingress Controller Deploy v2.1.0
# https://github.com/jetstack/cert-manager/releases/download/v1.0.2/cert-manager.yaml
################################################################################
echo "================================================================="
echo "Cert-Manager FOR Install EKS ALB Ingress Controller Deploy v2.1.0"
echo "================================================================="
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.0.2/cert-manager.yaml

sleep 60

################################################################################
# EKS ALB Ingress Controller Deploy v2.1.0
# https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.1.0/docs/install/v2_1_0_full.yaml
################################################################################
cat > 02-eks-alb-ingress-controller.yaml << EOF
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  annotations:
    controller-gen.kubebuilder.io/version: v0.4.0
  creationTimestamp: null
  labels:
    app.kubernetes.io/name: aws-load-balancer-controller
  name: targetgroupbindings.elbv2.k8s.aws
spec:
  additionalPrinterColumns:
    - JSONPath: .spec.serviceRef.name
      description: The Kubernetes Service's name
      name: SERVICE-NAME
      type: string
    - JSONPath: .spec.serviceRef.port
      description: The Kubernetes Service's port
      name: SERVICE-PORT
      type: string
    - JSONPath: .spec.targetType
      description: The AWS TargetGroup's TargetType
      name: TARGET-TYPE
      type: string
    - JSONPath: .spec.targetGroupARN
      description: The AWS TargetGroup's Amazon Resource Name
      name: ARN
      priority: 1
      type: string
    - JSONPath: .metadata.creationTimestamp
      name: AGE
      type: date
  group: elbv2.k8s.aws
  names:
    categories:
      - all
    kind: TargetGroupBinding
    listKind: TargetGroupBindingList
    plural: targetgroupbindings
    singular: targetgroupbinding
  scope: Namespaced
  subresources:
    status: {}
  validation:
    openAPIV3Schema:
      description: TargetGroupBinding is the Schema for the TargetGroupBinding API
      properties:
        apiVersion:
          description: 'APIVersion defines the versioned schema of this representation
            of an object. Servers should convert recognized schemas to the latest
            internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources'
          type: string
        kind:
          description: 'Kind is a string value representing the REST resource this
            object represents. Servers may infer this from the endpoint the client
            submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
          type: string
        metadata:
          type: object
        spec:
          description: TargetGroupBindingSpec defines the desired state of TargetGroupBinding
          properties:
            networking:
              description: networking provides the networking setup for ELBV2 LoadBalancer
                to access targets in TargetGroup.
              properties:
                ingress:
                  description: List of ingress rules to allow ELBV2 LoadBalancer to
                    access targets in TargetGroup.
                  items:
                    properties:
                      from:
                        description: List of peers which should be able to access
                          the targets in TargetGroup. At least one NetworkingPeer
                          should be specified.
                        items:
                          description: NetworkingPeer defines the source/destination
                            peer for networking rules.
                          properties:
                            ipBlock:
                              description: IPBlock defines an IPBlock peer. If specified,
                                none of the other fields can be set.
                              properties:
                                cidr:
                                  description: CIDR is the network CIDR. Both IPV4
                                    or IPV6 CIDR are accepted.
                                  type: string
                              required:
                                - cidr
                              type: object
                            securityGroup:
                              description: SecurityGroup defines a SecurityGroup peer.
                                If specified, none of the other fields can be set.
                              properties:
                                groupID:
                                  description: GroupID is the EC2 SecurityGroupID.
                                  type: string
                              required:
                                - groupID
                              type: object
                          type: object
                        type: array
                      ports:
                        description: List of ports which should be made accessible
                          on the targets in TargetGroup. If ports is empty or unspecified,
                          it defaults to all ports with TCP.
                        items:
                          properties:
                            port:
                              anyOf:
                                - type: integer
                                - type: string
                              description: The port which traffic must match. When
                                NodePort endpoints(instance TargetType) is used, this
                                must be a numerical port. When Port endpoints(ip TargetType)
                                is used, this can be either numerical or named port
                                on pods. if port is unspecified, it defaults to all
                                ports.
                              x-kubernetes-int-or-string: true
                            protocol:
                              description: The protocol which traffic must match.
                                If protocol is unspecified, it defaults to TCP.
                              enum:
                                - TCP
                                - UDP
                              type: string
                          type: object
                        type: array
                    required:
                      - from
                      - ports
                    type: object
                  type: array
              type: object
            serviceRef:
              description: serviceRef is a reference to a Kubernetes Service and ServicePort.
              properties:
                name:
                  description: Name is the name of the Service.
                  type: string
                port:
                  anyOf:
                    - type: integer
                    - type: string
                  description: Port is the port of the ServicePort.
                  x-kubernetes-int-or-string: true
              required:
                - name
                - port
              type: object
            targetGroupARN:
              description: targetGroupARN is the Amazon Resource Name (ARN) for the
                TargetGroup.
              type: string
            targetType:
              description: targetType is the TargetType of TargetGroup. If unspecified,
                it will be automatically inferred.
              enum:
                - instance
                - ip
              type: string
          required:
            - serviceRef
            - targetGroupARN
          type: object
        status:
          description: TargetGroupBindingStatus defines the observed state of TargetGroupBinding
          properties:
            observedGeneration:
              description: The generation observed by the TargetGroupBinding controller.
              format: int64
              type: integer
          type: object
      type: object
  version: v1alpha1
  versions:
    - name: v1alpha1
      served: true
      storage: false
    - name: v1beta1
      served: true
      storage: true
status:
  acceptedNames:
    kind: ""
    plural: ""
  conditions: []
  storedVersions: []
---
apiVersion: admissionregistration.k8s.io/v1beta1
kind: MutatingWebhookConfiguration
metadata:
  annotations:
    cert-manager.io/inject-ca-from: kube-system/aws-load-balancer-serving-cert
  creationTimestamp: null
  labels:
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-webhook
webhooks:
  - clientConfig:
      caBundle: Cg==
      service:
        name: aws-load-balancer-webhook-service
        namespace: kube-system
        path: /mutate-v1-pod
    failurePolicy: Fail
    name: mpod.elbv2.k8s.aws
    namespaceSelector:
      matchExpressions:
        - key: elbv2.k8s.aws/pod-readiness-gate-inject
          operator: In
          values:
            - enabled
    rules:
      - apiGroups:
          - ""
        apiVersions:
          - v1
        operations:
          - CREATE
        resources:
          - pods
    sideEffects: None
  - clientConfig:
      caBundle: Cg==
      service:
        name: aws-load-balancer-webhook-service
        namespace: kube-system
        path: /mutate-elbv2-k8s-aws-v1beta1-targetgroupbinding
    failurePolicy: Fail
    name: mtargetgroupbinding.elbv2.k8s.aws
    rules:
      - apiGroups:
          - elbv2.k8s.aws
        apiVersions:
          - v1beta1
        operations:
          - CREATE
          - UPDATE
        resources:
          - targetgroupbindings
    sideEffects: None
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  labels:
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller-leader-election-role
  namespace: kube-system
rules:
  - apiGroups:
      - ""
    resources:
      - configmaps
    verbs:
      - create
  - apiGroups:
      - ""
    resourceNames:
      - aws-load-balancer-controller-leader
    resources:
      - configmaps
    verbs:
      - get
      - update
      - patch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  creationTimestamp: null
  labels:
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller-role
rules:
  - apiGroups:
      - ""
    resources:
      - endpoints
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - events
    verbs:
      - create
      - patch
  - apiGroups:
      - ""
    resources:
      - namespaces
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - nodes
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - pods
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - pods/status
    verbs:
      - patch
      - update
  - apiGroups:
      - ""
    resources:
      - secrets
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - services
    verbs:
      - get
      - list
      - patch
      - update
      - watch
  - apiGroups:
      - ""
    resources:
      - services/status
    verbs:
      - patch
      - update
  - apiGroups:
      - elbv2.k8s.aws
    resources:
      - targetgroupbindings
    verbs:
      - create
      - delete
      - get
      - list
      - patch
      - update
      - watch
  - apiGroups:
      - elbv2.k8s.aws
    resources:
      - targetgroupbindings/status
    verbs:
      - patch
      - update
  - apiGroups:
      - extensions
    resources:
      - ingresses
    verbs:
      - get
      - list
      - patch
      - update
      - watch
  - apiGroups:
      - extensions
    resources:
      - ingresses/status
    verbs:
      - patch
      - update
  - apiGroups:
      - networking.k8s.io
    resources:
      - ingressclasses
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - networking.k8s.io
    resources:
      - ingresses
    verbs:
      - get
      - list
      - patch
      - update
      - watch
  - apiGroups:
      - networking.k8s.io
    resources:
      - ingresses/status
    verbs:
      - patch
      - update
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller-leader-election-rolebinding
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: aws-load-balancer-controller-leader-election-role
subjects:
  - kind: ServiceAccount
    name: aws-load-balancer-controller
    namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller-rolebinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: aws-load-balancer-controller-role
subjects:
  - kind: ServiceAccount
    name: aws-load-balancer-controller
    namespace: kube-system
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-webhook-service
  namespace: kube-system
spec:
  ports:
    - port: 443
      targetPort: 9443
  selector:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: aws-load-balancer-controller
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/component: controller
      app.kubernetes.io/name: aws-load-balancer-controller
  template:
    metadata:
      labels:
        app.kubernetes.io/component: controller
        app.kubernetes.io/name: aws-load-balancer-controller
    spec:
      containers:
        - args:
            - --cluster-name=$AWS_EKS_CLUSTER_NAME
            - --ingress-class=alb
          image: amazon/aws-alb-ingress-controller:v2.1.0
          livenessProbe:
            failureThreshold: 2
            httpGet:
              path: /healthz
              port: 61779
              scheme: HTTP
            initialDelaySeconds: 30
            timeoutSeconds: 10
          name: controller
          ports:
            - containerPort: 9443
              name: webhook-server
              protocol: TCP
          resources:
            limits:
              cpu: 200m
              memory: 500Mi
            requests:
              cpu: 100m
              memory: 200Mi
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            runAsNonRoot: true
          volumeMounts:
            - mountPath: /tmp/k8s-webhook-server/serving-certs
              name: cert
              readOnly: true
      securityContext:
        fsGroup: 1337
      serviceAccountName: aws-load-balancer-controller
      terminationGracePeriodSeconds: 10
      volumes:
        - name: cert
          secret:
            defaultMode: 420
            secretName: aws-load-balancer-webhook-tls
---
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  labels:
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-serving-cert
  namespace: kube-system
spec:
  dnsNames:
    - aws-load-balancer-webhook-service.kube-system.svc
    - aws-load-balancer-webhook-service.kube-system.svc.cluster.local
  issuerRef:
    kind: Issuer
    name: aws-load-balancer-selfsigned-issuer
  secretName: aws-load-balancer-webhook-tls
---
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  labels:
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-selfsigned-issuer
  namespace: kube-system
spec:
  selfSigned: {}
---
apiVersion: admissionregistration.k8s.io/v1beta1
kind: ValidatingWebhookConfiguration
metadata:
  annotations:
    cert-manager.io/inject-ca-from: kube-system/aws-load-balancer-serving-cert
  creationTimestamp: null
  labels:
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-webhook
webhooks:
  - clientConfig:
      caBundle: Cg==
      service:
        name: aws-load-balancer-webhook-service
        namespace: kube-system
        path: /validate-elbv2-k8s-aws-v1beta1-targetgroupbinding
    failurePolicy: Fail
    name: vtargetgroupbinding.elbv2.k8s.aws
    rules:
      - apiGroups:
          - elbv2.k8s.aws
        apiVersions:
          - v1beta1
        operations:
          - CREATE
          - UPDATE
        resources:
          - targetgroupbindings
    sideEffects: None
EOF

echo "================================================================="
echo "EKS ALB Ingress Controller Deploy v2.1.0"
echo "================================================================="
kubectl apply -f 02-eks-alb-ingress-controller.yaml

################################################################################
# EKS external-dns deploy
################################################################################
cat > 03-eks-external-dns-deploy.yaml << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-dns
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: external-dns
rules:
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get","watch","list"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get","watch","list"]
- apiGroups: ["extensions"] 
  resources: ["ingresses"] 
  verbs: ["get","watch","list"]
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: external-dns-viewer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: external-dns
subjects:
- kind: ServiceAccount
  name: external-dns
  namespace: default
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
spec:
  selector:
    matchLabels:
      app: external-dns
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: external-dns
    spec:
      serviceAccountName: external-dns
      containers:
      - name: external-dns
        image: registry.opensource.zalan.do/teapot/external-dns:v0.5.9
        args:
        - --source=service
        - --source=ingress
        - --domain-filter=$CLUSTER_NAME.
        - --provider=aws
        - --policy=upsert-only # would prevent ExternalDNS from deleting any records, omit to enable full synchronization
        - --aws-zone-type=public # only look at public hosted zones (valid values are public, private or no value for both)
        - --registry=txt
        - --txt-owner-id=$CLUSTER_NAME_MODI
EOF

echo "================================================================="
echo "kubectl external-dns deploy Apply"
echo "================================================================="
kubectl apply -f 03-eks-external-dns-deploy.yaml

################################################################################
# EKS Dashboard Admin
# 
################################################################################
cat > 04-eks-dashboard-admin.yaml << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin
  namespace: kube-system

---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: kubelet-api-admin
subjects:
- kind: User
  name: kubelet-api
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: system:kubelet-api-admin
  apiGroup: rbac.authorization.k8s.io
EOF

echo "================================================================="
echo "kubectl Dashboard Admin Apply"
echo "================================================================="
kubectl apply -f 04-eks-dashboard-admin.yaml

################################################################################
# EKS Dashboard Admin RBAC
# 
################################################################################
cat > 04-eks-dashboard-admin-rbac.yaml << EOF
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: system:aggregated-metrics-reader
  labels:
    rbac.authorization.k8s.io/aggregate-to-view: "true"
    rbac.authorization.k8s.io/aggregate-to-edit: "true"
    rbac.authorization.k8s.io/aggregate-to-admin: "true"
rules:
- apiGroups: ["metrics.k8s.io"]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: metrics-server:system:auth-delegator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: metrics-server-auth-reader
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: extension-apiserver-authentication-reader
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:metrics-server
rules:
- apiGroups:
  - ""
  resources:
  - pods
  - nodes
  - nodes/stats
  verbs:
  - get
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:metrics-server
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:metrics-server
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
EOF

echo "================================================================="
echo "kubectl Dashboard Admin RBAC Apply"
echo "================================================================="
kubectl apply -f 04-eks-dashboard-admin-rbac.yaml

################################################################################
# EKS Dashboard Metric Deployment
# 
################################################################################
cat > 04-eks-dashboard-metric-deployment.yaml << EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-server
  namespace: kube-system
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-server
  namespace: kube-system
  labels:
    k8s-app: metrics-server
spec:
  selector:
    matchLabels:
      k8s-app: metrics-server
  template:
    metadata:
      name: metrics-server
      labels:
        k8s-app: metrics-server
    spec:
      serviceAccountName: metrics-server
      volumes:
      # mount in tmp so we can safely use from-scratch images and/or read-only containers
      - name: tmp-dir
        emptyDir: {}
      containers:
      - name: metrics-server
        image: k8s.gcr.io/metrics-server-amd64:v0.3.4
        imagePullPolicy: Always
        volumeMounts:
        - name: tmp-dir
          mountPath: /tmp
        command:
        - /metrics-server
        - --kubelet-insecure-tls
        - --kubelet-preferred-address-types=Hostname,InternalDNS,InternalIP,ExternalDNS,ExternalIP
        - --logtostderr=true
        - --v=2
EOF

echo "================================================================="
echo "kubectl Dashboard Metric Deployment Apply"
echo "================================================================="
kubectl apply -f 04-eks-dashboard-metric-deployment.yaml

################################################################################
# EKS Dashboard Metric Service
# 
################################################################################
cat > 04-eks-dashboard-metric-svc.yaml << EOF
---
apiVersion: v1
kind: Service
metadata:
  name: metrics-server
  namespace: kube-system
  labels:
    kubernetes.io/name: "Metrics-server"
spec:
  selector:
    k8s-app: metrics-server
  ports:
  - port: 443
    protocol: TCP
    targetPort: 443
EOF

echo "================================================================="
echo "kubectl Dashboard Metric Service Apply"
echo "================================================================="
kubectl apply -f 04-eks-dashboard-metric-svc.yaml

################################################################################
# EKS Dashboard Metric API
# 
################################################################################
cat > 04-eks-dashboard-metric-api.yaml << EOF
---
apiVersion: apiregistration.k8s.io/v1
kind: APIService
metadata:
  name: v1beta1.metrics.k8s.io
spec:
  service:
    name: metrics-server
    namespace: kube-system
  group: metrics.k8s.io
  version: v1beta1
  insecureSkipTLSVerify: true
  groupPriorityMinimum: 100
  versionPriority: 100
EOF

echo "================================================================="
echo "kubectl Dashboard Metric API Apply"
echo "================================================================="
kubectl apply -f 04-eks-dashboard-metric-api.yaml

################################################################################
# EKS Cluster Autoscaler deploy
################################################################################
cat > 05-cluster-autoscaler.yaml << EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
  name: cluster-autoscaler
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-autoscaler
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
rules:
  - apiGroups: [""]
    resources: ["events", "endpoints"]
    verbs: ["create", "patch"]
  - apiGroups: [""]
    resources: ["pods/eviction"]
    verbs: ["create"]
  - apiGroups: [""]
    resources: ["pods/status"]
    verbs: ["update"]
  - apiGroups: [""]
    resources: ["endpoints"]
    resourceNames: ["cluster-autoscaler"]
    verbs: ["get", "update"]
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["watch", "list", "get", "update"]
  - apiGroups: [""]
    resources:
      - "pods"
      - "services"
      - "replicationcontrollers"
      - "persistentvolumeclaims"
      - "persistentvolumes"
    verbs: ["watch", "list", "get"]
  - apiGroups: ["extensions"]
    resources: ["replicasets", "daemonsets"]
    verbs: ["watch", "list", "get"]
  - apiGroups: ["policy"]
    resources: ["poddisruptionbudgets"]
    verbs: ["watch", "list"]
  - apiGroups: ["apps"]
    resources: ["statefulsets", "replicasets", "daemonsets"]
    verbs: ["watch", "list", "get"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses", "csinodes"]
    verbs: ["watch", "list", "get"]
  - apiGroups: ["batch", "extensions"]
    resources: ["jobs"]
    verbs: ["get", "list", "watch", "patch"]
  - apiGroups: ["coordination.k8s.io"]
    resources: ["leases"]
    verbs: ["create"]
  - apiGroups: ["coordination.k8s.io"]
    resourceNames: ["cluster-autoscaler"]
    resources: ["leases"]
    verbs: ["get", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: cluster-autoscaler
  namespace: kube-system
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["create","list","watch"]
  - apiGroups: [""]
    resources: ["configmaps"]
    resourceNames: ["cluster-autoscaler-status", "cluster-autoscaler-priority-expander"]
    verbs: ["delete", "get", "update", "watch"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-autoscaler
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-autoscaler
subjects:
  - kind: ServiceAccount
    name: cluster-autoscaler
    namespace: kube-system

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: cluster-autoscaler
  namespace: kube-system
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: cluster-autoscaler
subjects:
  - kind: ServiceAccount
    name: cluster-autoscaler
    namespace: kube-system

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-autoscaler
  namespace: kube-system
  labels:
    app: cluster-autoscaler
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cluster-autoscaler
  template:
    metadata:
      labels:
        app: cluster-autoscaler
      annotations:
        prometheus.io/scrape: 'true'
        prometheus.io/port: '8085'
    spec:
      serviceAccountName: cluster-autoscaler
      containers:
        - image: k8s.gcr.io/autoscaling/cluster-autoscaler:v1.17.3
          name: cluster-autoscaler
          resources:
            limits:
              cpu: 100m
              memory: 300Mi
            requests:
              cpu: 100m
              memory: 300Mi
          command:
            - ./cluster-autoscaler
            - --v=4
            - --stderrthreshold=info
            - --cloud-provider=aws
            - --skip-nodes-with-local-storage=false
            - --expander=least-waste
            - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/$AWS_EKS_CLUSTER_NAME
          volumeMounts:
            - name: ssl-certs
              mountPath: /etc/ssl/certs/ca-certificates.crt
              readOnly: true
          imagePullPolicy: "Always"
      volumes:
        - name: ssl-certs
          hostPath:
            path: "/etc/ssl/certs/ca-bundle.crt"
EOF

echo "================================================================="
echo "kubectl Cluster Autoscaler Apply"
echo "================================================================="
kubectl apply -f 05-cluster-autoscaler.yaml
