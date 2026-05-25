#!/bin/bash

# ------------------------------------------------------------------
# SAFE DEBUG MODE
# ------------------------------------------------------------------

set -x

# ------------------------------------------------------------------
# LOGGING
# ------------------------------------------------------------------

exec > /var/log/user-data.log 2>&1

echo "================================================="
echo "STARTING WORKER NODE CONFIGURATION"
echo "================================================="

# ------------------------------------------------------------------
# SET HOSTNAME
# ------------------------------------------------------------------

HOSTNAME=$(curl -s http://169.254.169.254/latest/meta-data/local-hostname)

hostnamectl set-hostname "$HOSTNAME"

echo "Hostname set to: $HOSTNAME"

# ------------------------------------------------------------------
# DISABLE SWAP
# ------------------------------------------------------------------

swapoff -a

sed -i '/swap/d' /etc/fstab

# ------------------------------------------------------------------
# SELINUX
# ------------------------------------------------------------------

setenforce 0 || true

sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config || true

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
# SYSCTL SETTINGS
# ------------------------------------------------------------------

cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

# ------------------------------------------------------------------
# UPDATE SYSTEM
# ------------------------------------------------------------------

dnf update -y

# ------------------------------------------------------------------
# INSTALL REQUIRED PACKAGES
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

systemctl status containerd --no-pager

# ------------------------------------------------------------------
# INSTALL KUBERNETES REPO
# ------------------------------------------------------------------

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repodata/repomd.xml.key
EOF

# ------------------------------------------------------------------
# INSTALL KUBERNETES COMPONENTS
# ------------------------------------------------------------------

dnf install -y kubelet kubeadm kubectl

systemctl enable --now kubelet

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
# WAIT FOR SSM JOIN COMMAND
# ------------------------------------------------------------------

echo "Waiting for kubeadm join command from SSM..."

until aws ssm get-parameter \
  --name "/kubeadm/prod/worker/join-command" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text \
  --region ${aws_region}; do

  echo "SSM parameter not ready yet..."
  sleep 15

done

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

echo "$JOIN_COMMAND"

# ------------------------------------------------------------------
# JOIN KUBERNETES CLUSTER
# ------------------------------------------------------------------

bash -c "$JOIN_COMMAND --cri-socket unix:///run/containerd/containerd.sock"

# ------------------------------------------------------------------
# COMPLETE
# ------------------------------------------------------------------

echo "================================================="
echo "WORKER NODE JOINED SUCCESSFULLY"
echo "================================================="