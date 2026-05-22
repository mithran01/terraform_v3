#!/bin/bash

## Configuration variables ##
pem_key_path="/home/ec2-user/demov2.pem"
control_plane_ips="/home/ec2-user/control-plane-ips.txt"

rocky_user="rocky"
amazon_user="ec2-user"

### step 1: update system
sudo dnf update -y

### step 2:Install python2 and pip
echo "[+] updating system packages"
sudo dnf install -y python3 python3-pip

### step 3: Install ansible
echo "[+] Installing ansible on controller node"
sudo pip3 install ansible

### step 4: create ansible directory
echo "[+] Creating /etc/ansible directory if not exist"
sudo mkdir -p /etc/ansible
sudo touch /etc/ansible/hosts
sudo touch /etc/ansible/ansible.cfg


### step 6: generate ssh key pair (if not exist)
if [ ! -f ~/.ssh/id_rsa ];then
    echo "[+] generating ssh key pair . . ."
    ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -q -N ""
else
    echo "[+] key pair already exist"
fi

### step 7: copy ssh public key to managed nodes
echo "[+] copying ssh key to managed node (control-plane)"

while read -r ip || [ -n "$ip" ];do
  [ -z "$ip" ] && continue
    ssh -n -o StrictHostKeyChecking=no -i "$pem_key_path" ${rocky_user}@"$ip" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo $(cat ~/.ssh/id_rsa.pub) >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
done < $control_plane_ips

### step 8: configure ansible inventory 
echo "[+] Writing inventory to /etc/ansible/hosts"
echo "[+] Writing inventory dynamically"

sudo tee /etc/ansible/hosts > /dev/null <<EOF
[controlplane]
$(awk '{print $1 " ansible_user=rocky"}' "$control_plane_ips")

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

### step 10: configure ansible.cfg
echo "[+] Writing basic ansible configuration ..."
sudo bash -c 'cat > /etc/ansible/ansible.cfg' << EOF
[defaults]
inventory = /etc/ansible/hosts
forks = 20
timeout = 30
host_key_checking = False
deprecation_warning = False
interpreter_python = auto_silent

[ssh_connection] 
pipelining = True 
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
EOF

### step 11: validate connection
echo "[+] validating ansible connection to all nodes"
if ansible all -m ping;then
    rm -rf $pem_key_path
    echo "[removed]: $pem_key_path key file"
else
    echo -e "\e[31m[FAILED]: ANSIBLE CONFIGURATION FAILED\e[0m"
    exit 1
fi

echo -e "\e[32m[SUCCESS]: ansible controller and worker node are configured succesfully\e[0m"