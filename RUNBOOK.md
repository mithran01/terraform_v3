# RUNBOOK.md

# how to get kubectl in bastion host
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x kubectl

sudo mv kubectl /usr/local/bin/

# how to create a proxy server
dnf search squid

dnf install squid -y

sudo cp /etc/squid/squid.conf /etc/squid/squid.conf.backup

        acl k8s src 172.31.4.120/32

        acl allowed_domain dstdomain \
            .google.com \
            .github.com

        http_access allow k8s

        http_access deny all

        http_port 3128

sudo squid -k parse

sudo systemctl enable --now squid

sudo systemctl status squid

sudo systemctl restart squid

curl -v   --interface 172.31.4.130   -x http://172.31.36.103:3128   https://google.com


# helm repo add for egress gateway
helm repo list

helm repo add cilium https://helm.cilium.io/

helm search repo cilium/cilium --versions | grep '^cilium/cilium.*1.18.1'

helm upgrade cilium cilium/cilium \
  -n kube-system \
  --version 1.18.1 \
  --reuse-values \
  --set egressGateway.enabled=true


  1. Initial state

Cilium was healthy and all nodes were Ready.

Cilium showed:

Cilium: 1.18.1
KubeProxyReplacement: False
Masquerading: IPTables
2. Enabled Egress Gateway

Changed the Helm value:

helm upgrade cilium cilium/cilium \
  -n kube-system \
  --version 1.18.1 \
  --reuse-values \
  --set egressGateway.enabled=true

  Initially, Cilium failed with:

egress gateway requires
--enable-ipv4-masquerade="true"
and
--enable-bpf-masquerade="true"
3. Enabled BPF masquerading

Added:

--set bpf.masquerade=true

Full command:

helm upgrade cilium cilium/cilium \
  -n kube-system \
  --version 1.18.1 \
  --reuse-values \
  --set egressGateway.enabled=true \
  --set bpf.masquerade=true

Configuration then showed:

enable-egress-gateway: "true"
enable-bpf-masquerade: "true"
enable-ipv4-masquerade: "true"

4. New problem — missing CRD

Cilium agents then reported:

Still waiting for Cilium Operator to register CRDs
CRDs=[crd:ciliumegressgatewaypolicies.cilium.io]

Checking:

kubectl get crd ciliumegressgatewaypolicies.cilium.io

returned:

NotFound

The important discovery was that the existing cluster had standard Cilium CRDs, but did not have:

ciliumegressgatewaypolicies.cilium.io

The Cilium agents therefore remained unready.

5. Node became NotReady

The newly joined node:

172.31.40.0

showed:

Ready: False

with:

NetworkPluginNotReady
cni plugin not initialized

The reason was that the Cilium agent on that node could not become ready.

6. Recovery

Disabled Egress Gateway and BPF masquerading again through Helm:

helm upgrade cilium cilium/cilium \
  -n kube-system \
  --version 1.18.1 \
  --reuse-values \
  --set egressGateway.enabled=false \
  --set bpf.masquerade=false

After the Cilium DaemonSet recovered:

kubectl get nodes

all three nodes became:

172.31.33.4    Ready
172.31.40.0    Ready
172.31.5.196   Ready


##

helm upgrade cilium cilium/cilium \
  -n kube-system \
  --version 1.18.1 \
  --reuse-values \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=172.31.33.4 \
  --set k8sServicePort=6443 \
  --set bpf.masquerade=true \
  --set egressGateway.enabled=true
   
   kubectl get crd ciliumegressgatewaypolicies.cilium.io
   kubectl get pods -n kube-system -l k8s-app=cilium -o wide

   [ec2-user@ip-172-31-45-49 ~]$ kubectl get ciliumegressgatewaypolicy
NAME               AGE
fqdn-test-egress   8s


   kubectl label node ip-172-31-40-0.ec2.internal egress-gateway=true
# cilium 
kubectl -n kube-system exec ds/cilium -- cilium-dbg version
kubectl -n kube-system exec ds/cilium -- cilium-dbg status

# Operational Runbook

## Check Cluster Health

kubectl get nodes

Expected:

All nodes Ready

---

## Check System Pods

kubectl get pods -A

Expected:

All critical components Running

---

## Check MariaDB

kubectl get pods -n openemr

Expected:

mariadb-0 Running

---

## Check Storage

kubectl get pvc -n openemr

Expected:

PVC Bound

---

## Check Autoscaler

kubectl logs -n kube-system deployment/cluster-autoscaler-aws-cluster-autoscaler

---

## Scale OpenEMR

kubectl scale deployment openemr --replicas=3 -n openemr

---

## Restart MariaDB

kubectl delete pod mariadb-0 -n openemr

Expected:

Pod recreated automatically

---

## Troubleshooting

### Node Not Ready

Check:

kubectl describe node <node>

Check kubelet:

systemctl status kubelet

---

### PVC Pending

Check:

kubectl describe pvc

Check:

kubectl logs -n kube-system deployment/ebs-csi-controller

---

### Pod Stuck Pending

Check:

kubectl describe pod <pod>

Verify:

* Labels
* Taints
* Resources
* Storage

---

### Database Recovery Test

Delete pod:

kubectl delete pod mariadb-0 -n openemr

Verify:

Database starts successfully.
