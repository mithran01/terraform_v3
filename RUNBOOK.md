# RUNBOOK.md

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
