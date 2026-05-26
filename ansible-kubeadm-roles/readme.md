ANSIBLE_ROLES_PATH=./roles ansible-playbook -i /etc/ansible/hosts playbooks/kubernetes.yaml

ANSIBLE_ROLES_PATH=./roles ansible-playbook -i /etc/ansible/hosts playbooks/metrics-server.yaml

ANSIBLE_ROLES_PATH=./roles ansible-playbook -i /etc/ansible/hosts playbooks/ebs-csi.yaml

ANSIBLE_ROLES_PATH=./roles ansible-playbook -i /etc/ansible/hosts playbooks/efs-csi.yaml -e "efs_filesystem_id= "