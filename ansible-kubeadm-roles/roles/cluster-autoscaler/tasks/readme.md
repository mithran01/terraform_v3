kubectl get deploy -n kube-system | grep autoscaler

kubectl get pods -n kube-system | grep autoscaler

kubectl logs -n kube-system -l app.kubernetes.io/name=aws-cluster-autoscaler

kubectl get deployment cluster-autoscaler \
-n kube-system -o yaml

kubectl describe deployment -l app.kubernetes.io/name=aws-cluster-autoscaler -n kube-system

kubetcl get deployment -l app.kubernetes.io/name=aws-cluster-autoscaler -n kube-system -o yaml

kubectl describe sa cluster-autoscaler -n kube-system