# ARCHITECTURE.md

# OpenEMR Kubernetes Architecture

## Overview

Production-grade OpenEMR deployment on AWS using kubeadm Kubernetes.

## Components

### Control Plane

Responsibilities:

* API Server
* Scheduler
* Controller Manager
* etcd

Node Count:

* 1 (future HA planned)

---

### Data Plane

Purpose:

* OpenEMR application pods
* Ingress Controller
* Monitoring stack

Labels:

node-type=data-plane
role=worker

Scaling:

* Cluster Autoscaler enabled

---

### DB Plane

Purpose:

* MariaDB only

Labels:

node-type=db-plane
role=db

Taints:

dedicated=db:NoSchedule

---

### Storage

StorageClass:

gp3

Provisioner:

ebs.csi.aws.com

Features:

* Dynamic provisioning
* Volume expansion
* Retain policy

---

### Database

Deployment Type:

StatefulSet

Persistence:

EBS Volume

Service Types:

* Headless Service
* ClusterIP Service

---

### Networking

CNI:

Calico

Cloud Integration:

AWS Cloud Controller Manager

---

### Autoscaling

Cluster Autoscaler

Node Groups:

* Data Plane ASG
* DB Plane ASG

---

### Monitoring (Planned)

* Prometheus
* Grafana
* Alertmanager
* MariaDB Exporter

---

### Backups (Planned)

* EBS Snapshots
* mysqldump to S3
