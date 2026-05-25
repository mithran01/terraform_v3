#!/bin/bash

set -euxo pipefail

# ------------------------------------------------------------------
# LOGGING
# ------------------------------------------------------------------

exec > >(tee /var/log/user-data.log | logger -t user-data ) 2>&1

echo "STARTING WORKER NODE CONFIGURATION"

# ------------------------------------------------------------------
# HOSTNAME
# ------------------------------------------------------------------

hostnamectl set-hostname $(curl -s http://169.254.169.254/latest/meta-data/local-hostname)

# ------------------------------------------------------------------
# DISABLE SWAP
# ------------------------------------------------------------------

swapoff -a
sed -i '/swap/d' /etc/fstab

# ------------------------------------------------------------------
# KERNEL MODULES
# ------------------------------------------------------------------

cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# ------------------------------------------------------------------
# SYSCTL
# ------------------------------------------------------------------

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

# ------------------------------------------------------------------
# INSTALL CONTAINERD
# ------------------------------------------------------------------

dnf install -y yum-utils device-mapper-persistent-data lvm2

dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

dnf install -y containerd.io

mkdir -p /etc/containerd

containerd config default | tee /etc/containerd/config.toml

sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl enable containerd
systemctl restart containerd

# ------------------------------------------------------------------
# INSTALL KUBERNETES PACKAGES
# ------------------------------------------------------------------

cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repodata/repomd.xml.key
EOF

dnf install -y kubelet kubeadm kubectl

systemctl enable --now kubelet

# ------------------------------------------------------------------
# INSTALL AWS CLI V2
# ------------------------------------------------------------------

dnf install -y unzip curl

cd /tmp

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
  -o "awscliv2.zip"

unzip awscliv2.zip

./aws/install

rm -rf awscliv2.zip aws

aws --version

# ------------------------------------------------------------------
# WAIT FOR CONTROL PLANE
# ------------------------------------------------------------------

sleep 30

# ------------------------------------------------------------------
# FETCH JOIN COMMAND FROM SSM
# ------------------------------------------------------------------

JOIN_COMMAND=$(aws ssm get-parameter \
  --name "/kubeadm/prod/worker/join-command" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text \
  --region ${aws_region})

echo "JOIN COMMAND FETCHED"

# ------------------------------------------------------------------
# JOIN CLUSTER
# ------------------------------------------------------------------

eval "$JOIN_COMMAND --cri-socket unix:///run/containerd/containerd.sock"

echo "WORKER NODE JOINED SUCCESSFULLY"