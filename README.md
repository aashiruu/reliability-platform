## Reliability-First Cloud Platform (AWS EKS + GitOps + Observability)
An end-to-end, production-ready cloud infrastructure designed for high availability and deep observability. This platform leverages Infrastructure as Code (IaC) to provision a resilient environment on AWS, featuring a self-healing microservice architecture.

### System Architecture
![Architecture](terraform/graph.png)

The full architecture includes a Multi-AZ VPC, managed RDS/Redis, and an EKS cluster with optimized pod density.

**Cloud Provider**: AWS (VPC, EKS, RDS, ElastiCache, IAM)

**Provisioning**: Terraform (IaC)

**Orchestration**: Kubernetes (Amazon EKS)

**Deployment**: ArgoCD (GitOps Workflow)

**Application**: FastAPI (Python 3.11)

**Observability**: Prometheus Operator & Grafana

### Key Features
1. **GitOps CD Workflow**
Using ArgoCD, the platform follows a strict GitOps model. Any changes pushed to the /k8s directory in GitHub are automatically synchronized with the EKS cluster, ensuring zero drift between code and production.

2. **Self-Healing & Resiliency**
The application is configured with replicas: 3 and native Kubernetes liveness probes. During testing, manual pod terminations resulted in instantaneous recovery with zero downtime, as managed by the Kubernetes ReplicaSet controller.

3. **Deep Observability**
The FastAPI application is instrumented to export real-time metrics. A custom Grafana dashboard tracks:

**Traffic**: Total requests and Requests Per Second (RPS).

**Latency**: Average and P99 response times.

**Errors**: HTTP 2xx/4xx/5xx error rates.

**Saturation**: CPU and Memory utilization per pod.

### Technical Challenges & Solutions
**The "Pod Density" hurdle**
* Problem: On t3.small nodes, the default ENI limit capped pod capacity at 11 per node, preventing the heavy Prometheus stack from scheduling.
* Solution: Implemented VPC Prefix Delegation and scaled the node group to 4 managed nodes to provide enough IP headroom for the monitoring stack and application.

**Persistent Storage for Metrics**
* Problem: Prometheus requires persistent storage to keep metric history across restarts.
* Solution: Configured the AWS EBS CSI Driver with appropriate IAM OpenID Connect (OIDC) roles to allow dynamic provisioning of EBS volumes as PersistentVolumeClaims (PVCs).

### Proof of Life
* API Response

<img width="512" height="292" alt="image" src="https://github.com/user-attachments/assets/d0cf4db5-4c3d-4873-ba15-283a1417f198" />

*Confirmed connection between FastAPI, RDS Postgres, and ElastiCache Redis.*

* ArgoCD Synchronization

<img width="512" height="253" alt="image" src="https://github.com/user-attachments/assets/c48dacfe-c8e4-4142-9952-46c1ba9aa927" />

* Grafana Metrics

<img width="512" height="243" alt="image" src="https://github.com/user-attachments/assets/a0104a41-145e-4a31-af2f-b75ecea28caa" />

.

<img width="512" height="243" alt="image" src="https://github.com/user-attachments/assets/35f519c6-52f3-46c8-8f56-398933efaf46" />

### How to Run (Local)
**Infrastructure**: 
```
cd terraform && terraform apply
```

**Access EKS**: 
```
aws eks update-kubeconfig --name reliability-cluster
```

**Metrics**: 
```
helm install monitoring prometheus-community/kube-prometheus-stack
```
