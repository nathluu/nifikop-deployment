# nifikop-deployment
Deploy NiFi cluster using NiFiKop

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.5/cert-manager.crds.yaml

# Add the jetstack helm repo
helm repo add jetstack https://charts.jetstack.io
helm repo update

# You have to create the namespace before executing following command
kubectl create namespace cert-manager
helm install cert-manager --namespace cert-manager --version v1.14.5 jetstack/cert-manager

# Install nifikop

helm install nifikop \
    oci://ghcr.io/konpyutaika/helm-charts/nifikop \
    --namespace=nifi \
    --version 1.8.0 \
    --set image.repository=docker.io/nathluu/nifikop \
    --set image.tag=v1.8.0-release \
    --set resources.requests.memory=256Mi \
    --set resources.requests.cpu=250m \
    --set resources.limits.memory=256Mi \
    --set resources.limits.cpu=250m \
    --set namespaces={"nifi"}

# Install zookeeper fro all nifi cluster
helm install zookeeper oci://registry-1.docker.io/bitnamicharts/zookeeper \
	--namespace=nifi \
	--set replicaCount=1 \
	--set networkPolicy.enabled=false
