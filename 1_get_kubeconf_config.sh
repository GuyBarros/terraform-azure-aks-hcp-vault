terraform output -raw kubeconfig > kubeconfig_admin
export KUBECONFIG=$PWD/kubeconfig_admin
kubectl get nodes