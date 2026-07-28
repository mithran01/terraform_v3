Part 1
Helm repository
Helm install
Namespace
Wait for operator

Part 2
Complete CephCluster (PVC-backed OSDs using your AWS EBS CSI gp3 StorageClass)

Part 3
Toolbox
CephBlockPool
CephFilesystem
Block StorageClass
CephFS StorageClass

Part 4
Verification
Health checks
Idempotent wait logic
Final tasks/main.yml assembled


kubectl get pods -n rook-ceph -o wide

kubectl get jobs -n rook-ceph

kubectl get cephcluster -n rook-ceph

kubectl describe cephcluster rook-ceph -n rook-ceph

kubectl describe pod rook-ceph-osd-0-7b4ff8c788-6wbpj -n rook-ceph

kubectl logs deploy/rook-ceph-operator -n rook-ceph --tail=100

lsblk

kubectl get pvc -n rook-ceph

kubectl get deployment -n rook-ceph

kubectl get rs -n rook-ceph