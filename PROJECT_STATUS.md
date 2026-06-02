# OpenEMR on AWS Kubernetes (kubeadm)

## Project Status

Last Updated: 2026-06-01

---

# 1. Project Overview

Goal:
Deploy a production-grade OpenEMR platform on AWS using kubeadm Kubernetes with dedicated application and database node groups, persistent storage, backups, monitoring, and disaster recovery.

---

# 2. Architecture

## Kubernetes

* Distribution: kubeadm
* Kubernetes Version: v1.30.14
* Container Runtime: containerd
* OS: Rocky Linux 9

## Networking

* AWS VPC
* Calico CNI
* AWS Cloud Controller Manager (CCM)

## Storage

* EBS CSI Driver
* StorageClass: gp3
* Reclaim Policy: Retain
* Volume Binding Mode: WaitForFirstConsumer

## Compute Layers

### Control Plane

* Instance Type: t3.medium
* Count: 1

### Data Plane

Purpose:

* OpenEMR
* Ingress
* Application workloads

Labels:

node-type=data-plane
role=worker
environment=prod

### DB Plane

Purpose:

* MariaDB only

Labels:

node-type=db-plane
role=db
environment=prod

Taints:

dedicated=db:NoSchedule

---

# 3. Infrastructure State

## Completed

### Bootstrap

Status: COMPLETE

* Terraform backend configured
* S3 state management configured
* IAM foundation created

### Control Plane

Status: COMPLETE

* kubeadm initialized
* admin.conf configured
* control plane operational

### Cloud Controller Manager

Status: COMPLETE

* AWS CCM installed
* Provider IDs populated
* Internal IPs populated
* External IPs populated

### Calico

Status: COMPLETE

* Pod networking operational

### EBS CSI Driver

Status: COMPLETE

* Dynamic volume provisioning operational
* PVC -> PV workflow validated

### Metrics Server

Status: COMPLETE

* kubectl top operational

### Cluster Autoscaler

Status: COMPLETE

* Auto-discovery operational
* ASG integration validated
* Scale-up testing completed

### Data Plane

Status: COMPLETE

* ASG operational
* Nodes joining automatically
* Labels applied automatically

### DB Plane

Status: COMPLETE

* Dedicated node group
* Dedicated taints
* Dedicated labels
* EBS CSI operational

### MariaDB

Status: COMPLETE

* Namespace created
* Secret management implemented
* Headless service deployed
* StatefulSet deployed
* Persistent volume attached
* Pod running successfully

---

# 4. Current Cluster State

Control Plane:

* 1 node

Data Plane:

* 1+ autoscaling nodes

DB Plane:

* 1 dedicated node

MariaDB:

* StatefulSet
* 1 replica

---

# 5. Storage

## StorageClass

Name:

gp3

Properties:

* Provisioner: ebs.csi.aws.com
* Reclaim Policy: Retain
* Allow Expansion: true
* WaitForFirstConsumer

## MariaDB Volume

PVC:

mariadb-data-mariadb-0

Storage:

10Gi

Type:

gp3

---

# 6. Backup Strategy

Status: PLANNED

## EBS Snapshots

Goal:

* Daily snapshots
* Retention policy

Tool:

* AWS DLM
* AWS Backup

## Logical Backups

Goal:

* Nightly mysqldump

Destination:

* S3

Retention:

* 30 days

---

# 7. Monitoring

Status: PLANNED

Components:

* Prometheus
* Grafana
* Node Exporter
* MariaDB Exporter

---

# 8. Disaster Recovery

Status: PLANNED

Recovery Objectives:

RPO:

* 24 hours

RTO:

* 1 hour

Recovery Sources:

* EBS snapshots
* mysqldump backups
* Terraform state
* Git repository

---

# 9. Security

Implemented:

* IAM Roles
* SSM Access
* IMDSv2 Required
* EBS Persistent Storage
* Dedicated DB Nodes

Planned:

* WAF
* GuardDuty
* Security Hub
* Shield
* Secrets Rotation

---

# 10. Pending Tasks

Priority 1

* VolumeSnapshotClass
* Snapshot Controller
* EBS Snapshot Automation
* MariaDB S3 Backup Job

Priority 2

* OpenEMR Deployment
* OpenEMR PVC
* OpenEMR Ingress

Priority 3

* Prometheus
* Grafana
* Alerting

Priority 4

* Multi-AZ Database Design
* Read Replicas
* DR Environment

---

# 11. GitHub Actions

Existing Pipelines

* pipeline-00
* pipeline-01
* pipeline-1
* pipeline-2

Planned

* pipeline-3 (DB Plane)
* pipeline-4 (MariaDB)
* pipeline-5 (OpenEMR)

Destroy Pipelines

* destroy-bootstrap
* destroy-control-plane
* destroy-data-plane
* destroy-db-plane

---

# 12. Known Decisions

Decision:
Use dedicated DB nodes.

Reason:
Prevent application workloads from consuming database resources.

Decision:
Use StatefulSet for MariaDB.

Reason:
Stable identity and persistent storage.

Decision:
Use EBS CSI Driver.

Reason:
Native AWS block storage integration.

Decision:
Use gp3 volumes.

Reason:
Cost/performance balance.

Decision:
Use ReclaimPolicy Retain.

Reason:
Protect database volumes from accidental deletion.
