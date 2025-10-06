export VAULT_TOKEN=<YOUR_TOKEN_HERE>
export VAULT_NAMESPACE=root
export VAULT_ADDR=<vault_address_here>
export VAULT_SKIP_VERIFY=true

helm install --create-namespace --namespace vault-secrets-operator vault-secrets-operator hashicorp/vault-secrets-operator

vault auth enable jwt

vault auth list -format=json | jq -r '.["jwt/"].accessor' > /tmp/accessor_jwt.txt

vault write -namespace="admin/tenant-1" auth/jwt/role/my-app \
  role_type="jwt" \
  bound_audiences="https://kubernetes.default.svc" \
  user_claim="sub" \
  bound_subject="system:serviceaccount:app-1:my-app" \
  policies="pki" \
  ttl="1h"


set VAULT_TOKEN=<Copia aqui o token do vault UI>
set VAULT_NAMESPACE=<NAMESPACE>
set VAULT_ADDR=<VAULT_ADDR>
set VAULT_SKIP_VERIFY=true

kubectl create clusterrolebinding \
  service-account-issuer-discovery-unauthenticated \
  --clusterrole=system:service-account-issuer-discovery \
  --group=system:unauthenticated

openssl s_client -showcerts -connect guy-aks-f2lkx-m01wqt8n.hcp.uksouth.azmk8s.io:443 </dev/null 2>/dev/null | \
sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' > kubernetes.pem



vault write -namespace=$VAULT_NAMESPACE auth/jwt/config \
jwks_url="https://guy-aks-f2lkx-m01wqt8n.hcp.uksouth.azmk8s.io:443/openid/v1/jwks" \
jwks_ca_pem=@kubernetes.pem


openssl s_client -showcerts -connect vault.guystack1.guy.aws.sbx.hashicorpdemo.com:8200 </dev/null 2>/dev/null | \
sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' > vault_ca.pem

kubectl create secret generic vault-cacert \
--namespace=vault-secrets-operator \
--from-literal=ca.crt="$(cat vault_ca.pem)"

kubectl apply -f - <<EOF
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultConnection
metadata:
  name: default
  namespace: vault-secrets-operator
spec:
  address: "https://vault.guystack1.guy.aws.sbx.hashicorpdemo.com:8200"
  tlsServerName: "vault.guystack1.guy.aws.sbx.hashicorpdemo.com"
  caCertSecretRef: "vault-cacert"
  skipTLSVerify: true
EOF



az aks show -n guy-aks-f2lkx -g guy-aks --query "oidcIssuerProfile.issuerUrl" -otsv

