# DECISIONS.md

# Architecture Decision Record

## ADR-001

Decision:

Use kubeadm instead of EKS.

Reason:

* Lower cost
* Greater control
* Better learning opportunity

---

## ADR-002

Decision:

Use AWS CCM.

Reason:

* Native AWS integration
* Automatic node metadata
* LoadBalancer support

---

## ADR-003

Decision:

Use EBS CSI Driver.

Reason:

* Native persistent storage
* Dynamic provisioning
* Snapshot support

---

## ADR-004

Decision:

Dedicated DB Plane.

Reason:

* Isolation from application workloads
* Predictable database performance

---

## ADR-005

Decision:

MariaDB StatefulSet.

Reason:

* Stable pod identity
* Stable storage mapping
* Easier recovery

---

## ADR-006

Decision:

StorageClass ReclaimPolicy = Retain.

Reason:

* Prevent accidental database loss

---

## ADR-007

Decision:

Use Cluster Autoscaler.

Reason:

* Cost optimization
* Automatic node provisioning

---

## ADR-008

Decision:

Use gp3 volumes.

Reason:

* Better price/performance than gp2
