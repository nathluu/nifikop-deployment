## Procedure
**Step 1:** Install kubectl, helm, kubelogin, istioctl
```bash
curl -LO https://github.com/istio/istio/releases/download/1.22.0/istioctl-1.22.0-linux-amd64.tar.gz
tar -xf istioctl-1.22.0-linux-amd64.tar.gz
sudo install istioctl /usr/local/bin/
``` 

**Step 2:** Generate CA, certificates and keys  
```bash
# Generate CA crt and key
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=TMA Inc./CN=tmanet.com' -keyout tmanet.com.key -out tmanet.com.crt
# Generate Istio Gateway TLS crt and key
openssl req -out gw.tmanet.com.csr -newkey rsa:2048 -nodes -keyout gw.tmanet.com.key -subj "/CN=*.tmanet.com/O=DC"
openssl x509 -req -days 365 -CA tmanet.com.crt -CAkey tmanet.com.key -set_serial 0 -in gw.tmanet.com.csr -out gw.tmanet.com.crt
```

**Step 3:** Install istio
```bash
chmod +x setup-istio.sh
./setup-istio.sh
```

**Step 4:** Create a secret for the ingress gateway  
```bash
kubectl create -n istio-system secret generic gw-credential --from-file=tls.key=gw.tmanet.com.key \
--from-file=tls.crt=gw.tmanet.com.crt --from-file=ca.crt=tmanet.com.crt
# kubectl create -n istio-system secret tls gw-credential --cert=gw.tmanet.com.crt --key=gw.tmanet.com.key --cacert=tmanet.com.crt # Another way to create k8s secret for TLS
# kubectl create -n istio-system secret generic client-credential --from-file=tls.key=client.gateway.key --from-file=tls.crt=client.gateway.crt --from-file=ca.crt=tmanet.com.crt # Use this command for mTLS
```

**Step 5:** Install cert-manager
# You have to create the namespace before executing following command
```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
kubectl create namespace cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.5/cert-manager.crds.yaml
helm install cert-manager --namespace cert-manager --version v1.14.5 jetstack/cert-manager
```

# nifikop-deployment
Deploy NiFi cluster using NiFiKop


**Step 6:** Create cert-manager Issuer
```bash
kubectl create ns nifi
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=TMA Inc./CN=certs.tmanet.com' -keyout certs.tmanet.com.key -out certs.tmanet.com.crt
kubectl create -n nifi secret tls cert-issuer-secret --cert=certs.tmanet.com.crt --key=certs.tmanet.com.key
kubectl apply -n nifi -f cert-manager-issuer.yaml
```



# Install nifikop
```bash
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
```

# Install zookeeper fro all nifi cluster
```bash
helm install zookeeper oci://registry-1.docker.io/bitnamicharts/zookeeper \
	--namespace=nifi \
	--set replicaCount=1 \
	--set networkPolicy.enabled=false
```


# Deploy nifi cluster
```bash
kubectl config set-context --current --namespace=nifi
kubectl apply -f simplenificluster_test.yaml
kubectl apply -f istio-cfg.yaml
```

NOTES:
It seems istio v1.22.0 has issue with destination rule TLS SIMPLE