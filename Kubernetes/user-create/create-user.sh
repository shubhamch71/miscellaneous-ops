#!/bin/bash

# === CONFIG ===
NAMESPACE="test"
SERVICE_ACCOUNT="dev-user"
ROLE_NAME="pod-reader"
SECRET_NAME="${SERVICE_ACCOUNT}-token"
KUBECONFIG_FILE="dev-user.kubeconfig"

echo "🔧 Creating namespace: $NAMESPACE"
kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$NAMESPACE"

echo "🔧 Creating ServiceAccount: $SERVICE_ACCOUNT"
kubectl create serviceaccount "$SERVICE_ACCOUNT" -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "🔧 Creating Role: $ROLE_NAME"
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: $NAMESPACE
  name: $ROLE_NAME
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
EOF

echo "🔧 Creating RoleBinding"
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${ROLE_NAME}-binding
  namespace: $NAMESPACE
subjects:
- kind: ServiceAccount
  name: $SERVICE_ACCOUNT
  namespace: $NAMESPACE
roleRef:
  kind: Role
  name: $ROLE_NAME
  apiGroup: rbac.authorization.k8s.io
EOF

echo "🔧 Creating ServiceAccount token Secret (Kubernetes v1.24+)"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: $SECRET_NAME
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/service-account.name: "$SERVICE_ACCOUNT"
type: kubernetes.io/service-account-token
EOF

echo "⏳ Waiting for token to be populated..."
sleep 5

echo "🔐 Fetching token and CA certificate..."
USER_TOKEN=$(kubectl get secret $SECRET_NAME -n $NAMESPACE -o jsonpath='{.data.token}' | base64 -d)
CA_CERT=$(kubectl get secret $SECRET_NAME -n $NAMESPACE -o jsonpath='{.data.ca\.crt}')
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
CLUSTER_ENDPOINT=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

echo "📄 Generating kubeconfig: $KUBECONFIG_FILE"
cat <<EOF > $KUBECONFIG_FILE
apiVersion: v1
kind: Config
clusters:
- name: $CLUSTER_NAME
  cluster:
    server: $CLUSTER_ENDPOINT
    certificate-authority-data: $CA_CERT
contexts:
- name: ${SERVICE_ACCOUNT}-context
  context:
    cluster: $CLUSTER_NAME
    namespace: $NAMESPACE
    user: $SERVICE_ACCOUNT
current-context: ${SERVICE_ACCOUNT}-context
users:
- name: $SERVICE_ACCOUNT
  user:
    token: $USER_TOKEN
EOF

echo "✅ Done!"
echo "👉 Try: kubectl --kubeconfig=$KUBECONFIG_FILE get pods"
echo "❌ Should be forbidden in other namespaces"
