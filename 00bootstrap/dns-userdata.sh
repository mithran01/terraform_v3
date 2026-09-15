#!/bin/bash

set -e

LOGFILE="/var/log/dns-bootstrap.log"

exec > >(tee -a "$LOGFILE") 2>&1

echo "===== DNS bootstrap started ====="

# --------------------------------------------------
# 1. Set hostname
# --------------------------------------------------

hostnamectl set-hostname dns01.lab.mithran.com


# --------------------------------------------------
# 2. Install BIND
# --------------------------------------------------

dnf install -y bind bind-utils


# --------------------------------------------------
# 3. Backup original configuration
# --------------------------------------------------

cp /etc/named.conf /etc/named.conf.original


# --------------------------------------------------
# 4. Configure named.conf
# --------------------------------------------------

cat > /etc/named.conf <<'EOF'
options {
    listen-on port 53 {
        127.0.0.1;
        172.31.32.10;
    };

    listen-on-v6 { none; };

    directory "/var/named";

    allow-query {
        localhost;
        172.31.0.0/16;
    };

    recursion no;

    dnssec-validation no;
};


zone "lab.mithran.com" IN {
    type master;
    file "lab.mithran.com.zone";
    allow-update { none; };
};


zone "32.31.172.in-addr.arpa" IN {
    type master;
    file "172.31.32.rev";
    allow-update { none; };
};
EOF


# --------------------------------------------------
# 5. Create forward DNS zone
# --------------------------------------------------

cat > /var/named/lab.mithran.com.zone <<'EOF'
$TTL 86400

@   IN  SOA dns01.lab.mithran.com. admin.lab.mithran.com. (
        2026091501
        3600
        1800
        604800
        86400
)

    IN  NS  dns01.lab.mithran.com.


dns01       IN  A   172.31.32.10
ntp01       IN  A   172.31.32.11
ldap01      IN  A   172.31.32.20
keycloak01  IN  A   172.31.32.30
teleport01  IN  A   172.31.32.40
bastion01   IN  A   172.31.32.50

cp01        IN  A   172.31.32.101
cp02        IN  A   172.31.32.102
cp03        IN  A   172.31.32.103

worker01    IN  A   172.31.32.111
worker02    IN  A   172.31.32.112
worker03    IN  A   172.31.32.113
EOF


# --------------------------------------------------
# 6. Create reverse DNS zone
# --------------------------------------------------

cat > /var/named/172.31.32.rev <<'EOF'
$TTL 86400

@   IN  SOA dns01.lab.mithran.com. admin.lab.mithran.com. (
        2026091501
        3600
        1800
        604800
        86400
)

    IN  NS  dns01.lab.mithran.com.


10  IN PTR dns01.lab.mithran.com.
11  IN PTR ntp01.lab.mithran.com.
20  IN PTR ldap01.lab.mithran.com.
30  IN PTR keycloak01.lab.mithran.com.
40  IN PTR teleport01.lab.mithran.com.
50  IN PTR bastion01.lab.mithran.com.

101 IN PTR cp01.lab.mithran.com.
102 IN PTR cp02.lab.mithran.com.
103 IN PTR cp03.lab.mithran.com.

111 IN PTR worker01.lab.mithran.com.
112 IN PTR worker02.lab.mithran.com.
113 IN PTR worker03.lab.mithran.com.
EOF


# --------------------------------------------------
# 7. Set permissions
# --------------------------------------------------

chown root:named /var/named/lab.mithran.com.zone
chmod 640 /var/named/lab.mithran.com.zone

chown root:named /var/named/172.31.32.rev
chmod 640 /var/named/172.31.32.rev


# --------------------------------------------------
# 8. Validate BIND configuration
# --------------------------------------------------

named-checkconf

named-checkzone \
  lab.mithran.com \
  /var/named/lab.mithran.com.zone

named-checkzone \
  32.31.172.in-addr.arpa \
  /var/named/172.31.32.rev


# --------------------------------------------------
# 9. Configure firewall
# --------------------------------------------------

# firewall-cmd --permanent --add-service=dns
# firewall-cmd --reload


# --------------------------------------------------
# 10. Enable and start BIND
# --------------------------------------------------

systemctl enable named
systemctl restart named


# --------------------------------------------------
# 11. Verify
# --------------------------------------------------

systemctl is-active named

ss -lntup | grep ':53'


echo "===== DNS bootstrap completed ====="