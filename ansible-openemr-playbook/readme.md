ansible-playbook -i /etc/ansible/hosts mariadb-playbook.yaml

ansible-playbook -i /etc/ansible/hosts redis-playbook.yaml

ansible-playbook -i /etc/ansible/hosts openemr-playbook.yaml


kubectl delete deployment openemr -n openemr

kubectl delete pvc openemr-default -n openemr

kubectl get pv

kubectl delete pv $(kubectl get pv | grep "efs-sc" | awk '{print $1}')

kubectl delete storageclass efs-sc

DROP DATABASE openemr;

CREATE DATABASE openemr;

GRANT ALL PRIVILEGES ON openemr.* TO 'openemr'@'%';

FLUSH PRIVILEGES;

 kubectl logs $(kubectl get pods -n openemr | grep "openemr" | awk '{print $1}') -n openemr

 kubectl exec -it $(kubectl get pods -n openemr | grep "openemr" | awk '{print $1}') -n openemr -- sh

  kubectl exec -it $(kubectl get pods -n openemr | grep "mariadb" | awk '{print $1}') -n openemr -- sh