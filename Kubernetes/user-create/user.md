**1. Create the test namespace (if it doesn’t exist)**
```bash
kubectl create namespace test
```

**2. Create a ServiceAccount**
```bash
kubectl create serviceaccount dev-user -n test
```

**3. Create a Role to allow viewing pods**
```bash
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: test
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
EOF
```

**4. Bind the Role to the ServiceAccount**
```bash
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-binding
  namespace: test
subjects:
- kind: ServiceAccount
  name: dev-user
  namespace: test
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
EOF
```
**5. Manually create a token for the ServiceAccount (K8s v1.24+)**
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: dev-user-token
  namespace: test
  annotations:
    kubernetes.io/service-account.name: dev-user
type: kubernetes.io/service-account-token
EOF
```

**6. Extract the token and CA cert**
```bash
# Get token value
kubectl get secret dev-user-token -n test -o jsonpath='{.data.token}' | base64 -d
```

Copy the output — this is your token 

```bash
# Get CA cert value (base64 encoded)
kubectl get secret dev-user-token -n test -o jsonpath='{.data.ca\.crt}'
```

Copy this base64 string — you’ll paste it into the kubeconfig.

**7. Get your cluster API endpoint and cluster name**
```bash
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'

kubectl config view --minify -o jsonpath='{.clusters[0].name}'

```

**8. Manually create the kubeconfig file**

```bash
# Save as: dev-user.kubeconfig
apiVersion: v1
kind: Config
clusters:
- name: minikube
  cluster:
    server: https://192.168.49.2:8443
    certificate-authority-data: <paste-ca-cert-base64>
contexts:
- name: dev-user-context
  context:
    cluster: minikube
    namespace: test
    user: dev-user
current-context: dev-user-context
users:
- name: dev-user
  user:
    token: <paste-token-here>
```

**9. Test the user access**
```bash
kubectl --kubeconfig=dev-user.kubeconfig get pods         # ✅ should work (test namespace)
kubectl --kubeconfig=dev-user.kubeconfig get pods -n default  # ❌ should be forbidden
```
