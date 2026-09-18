#!/bin/bash
set -euo pipefail

exec > >(tee -a /var/log/ntp-bootstrap.log) 2>&1

echo "===== NTP bootstrap started ====="

# 1. Set hostname
hostnamectl set-hostname ntp01.lab.mithran.com

# 2. Install Chrony
dnf install -y chrony

# 3. Back up the original configuration
cp -a /etc/chrony.conf /etc/chrony.conf.original

# 4. Configure Chrony for an isolated lab
cat > /etc/chrony.conf <<'EOF'
# NTP server: ntp01.lab.mithran.com

# No Internet NTP pools in this disconnected lab.
# The local directive allows clients to use this server's
# clock when no external reference is available.
local stratum 10

# Permit clients from the lab subnet.
allow 172.31.0.0/16

# Listen for NTP requests on IPv4.
bindaddress 172.31.32.11

# Store clock drift information.
driftfile /var/lib/chrony/drift

# Keep RTC synchronized with the system clock.
rtcsync

# Step the clock during the first updates if the offset is large.
makestep 1.0 3

# Record measurements and diagnostics.
logdir /var/log/chrony
EOF

# 5. Configure the firewall
#systemctl enable --now firewalld
#firewall-cmd --permanent --add-service=ntp
#firewall-cmd --reload

# 6. Enable and restart Chrony
systemctl enable chronyd
systemctl restart chronyd

# 7. Verify service
systemctl is-active chronyd
chronyc tracking
chronyc sources -v

echo "===== NTP bootstrap completed ====="