#!/bin/bash

# ------------------------------------------------------------------
# DEBUG
# ------------------------------------------------------------------

set -x

exec > /var/log/user-data.log 2>&1

echo "================================================="
echo "STARTING WORKER NODE CONFIGURATION"
echo "================================================="

# ------------------------------------------------------------------
# HOSTNAME
# ------------------------------------------------------------------

TOKEN=$(curl -X PUT \
http://169.254.169.254/latest/api/token \
-H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)

HOSTNAME=$(curl -s \
-H "X-aws-ec2-metadata-token:$TOKEN" \
http://169.254.169.254/latest/meta-data/local-hostname)

echo "Detected hostname: $HOSTNAME"

if [ -z "$$HOSTNAME" ]; then
  echo "ERROR: Failed to retrieve hostname from IMDS"
  exit 1
fi

echo "Detected hostname: $$HOSTNAME"

hostnamectl set-hostname "$$HOSTNAME"
echo "$$HOSTNAME" > /etc/hostname

# ------------------------------------------------------------------
# DISABLE SWAP
# ------------------------------------------------------------------

swapoff -a

sed -i '/swap/d' /etc/fstab

# ------------------------------------------------------------------
# SELINUX
# ------------------------------------------------------------------

setenforce 0 || true

sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' \
/etc/selinux/config || true

# ------------------------------------------------------------------
# KERNEL MODULES
# ------------------------------------------------------------------

cat <<EOF > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# ------------------------------------------------------------------
# SYSCTL
# ------------------------------------------------------------------

cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

# ------------------------------------------------------------------
# INSTALL PACKAGES
# ------------------------------------------------------------------

dnf install -y \
  curl \
  unzip \
  yum-utils \
  device-mapper-persistent-data \
  lvm2 \
  conntrack \
  socat \
  iproute-tc \
  dnf-plugins-core

# ------------------------------------------------------------------
# INSTALL CONTAINERD
# ------------------------------------------------------------------

dnf config-manager --add-repo \
https://download.docker.com/linux/centos/docker-ce.repo

dnf install -y containerd.io

mkdir -p /etc/containerd

containerd config default > /etc/containerd/config.toml

sed -i \
's/SystemdCgroup = false/SystemdCgroup = true/' \
/etc/containerd/config.toml

systemctl daemon-reload

systemctl enable --now containerd

# ------------------------------------------------------------------
# KUBERNETES REPO (MATCH CONTROL PLANE VERSION)
# ------------------------------------------------------------------

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
EOF

# ------------------------------------------------------------------
# INSTALL KUBERNETES COMPONENTS
# ------------------------------------------------------------------

dnf install -y \
  kubelet-1.30.14 \
  kubeadm-1.30.14 \
  kubectl-1.30.14

# ------------------------------------------------------------------
# KUBELET LABELS
# ------------------------------------------------------------------

cat <<EOF > /etc/sysconfig/kubelet
KUBELET_EXTRA_ARGS="--cloud-provider=external --hostname-override=$${HOSTNAME} --node-labels=node-type=data-plane,environment=prod,role=worker"
EOF

systemctl daemon-reload

systemctl enable kubelet

# ------------------------------------------------------------------
# INSTALL AWS CLI V2
# ------------------------------------------------------------------

cd /tmp

curl -o awscliv2.zip \
https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip

unzip awscliv2.zip

./aws/install

rm -rf aws awscliv2.zip

aws --version

# ------------------------------------------------------------------
# FETCH JOIN COMMAND
# ------------------------------------------------------------------

JOIN_COMMAND=$(aws ssm get-parameter \
  --name "/kubeadm/prod/worker/join-command" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text \
  --region ${aws_region})

echo "JOIN COMMAND FETCHED"

# ------------------------------------------------------------------
# START KUBELET
# ------------------------------------------------------------------

systemctl daemon-reload

systemctl enable --now kubelet

sleep 15

# ------------------------------------------------------------------
# JOIN CLUSTER
# ------------------------------------------------------------------

bash -c "$JOIN_COMMAND --cri-socket unix:///run/containerd/containerd.sock"

# ------------------------------------------------------------------
# WAIT FOR NODE STABILIZATION
# ------------------------------------------------------------------

sleep 30

# ------------------------------------------------------------------
# COMPLETE
# ------------------------------------------------------------------

echo "================================================="
echo "WORKER NODE JOINED SUCCESSFULLY"
echo "================================================="