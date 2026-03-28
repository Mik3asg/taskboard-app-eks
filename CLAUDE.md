# plane-app-aws-eks

Production-grade assignment: deploy a secure cloud-native application (Plane) on Amazon EKS using best practices for infrastructure provisioning, CI/CD automation, GitOps, and observability. The app must be accessible via HTTPS at `https://eks.<your-domain>` or `https://eks.labs.<your-domain>`.

## Assignment deliverables
1. **Terraform IaC** — EKS cluster, VPC, IAM roles, security groups using reusable modules + remote state (S3 + DynamoDB)
2. **NGINX Ingress Controller** — route traffic, HTTPS via TLS certs from CertManager
3. **CertManager** — Let's Encrypt SSL cert automation integrated with NGINX Ingress
4. **ExternalDNS** — auto-update Route53 DNS records from Kubernetes Ingress changes
5. **CI/CD Pipeline 1 (Terraform)** — plan/apply automation with validation and state management
6. **CI/CD Pipeline 2 (App)** — Checkov (Terraform security scan), Docker build + push to ECR, Trivy image scan, deploy to EKS
7. **ArgoCD GitOps** — auto-reconcile cluster state from Git on every push
8. **Monitoring** — Prometheus + Grafana with dashboards for CPU/memory, pod health, node status, Ingress traffic
9. **Architecture diagram** — full diagram (VPC, EKS, Ingress, ExternalDNS, CertManager, ArgoCD, Prometheus/Grafana)

## Goal
Full end-to-end deployment pipeline:
1. Terraform bootstrap (S3 + DynamoDB remote state)
2. Terraform infrastructure (VPC, EKS, DNS, IRSA)
3. Kubernetes manifests for the Plane app
4. ArgoCD for GitOps-based deployments
5. cert-manager + external-dns for TLS and DNS automation
6. GitHub Actions CI/CD
7. Prometheus + Grafana monitoring

## Application — TaskBoard
Custom app built to demonstrate the full DevOps pipeline. A simple task manager (create / complete / delete tasks) using:
- **Frontend:** React + Vite, served by nginx (port 80)
- **Backend:** Node.js + Express REST API (port 8000)
- **Database:** PostgreSQL 15 (tasks table, auto-migrated on startup)
- **Cache:** Redis 7 (caches `GET /api/tasks` for 60s, invalidated on writes)

Local dev: `docker compose -f docker/docker-compose.yml up --build` → open http://localhost:3000

## Project structure
```
app/
  frontend/         # React + Vite source (src/App.jsx, vite.config.js)
  backend/          # Node.js + Express source (src/index.js, routes/tasks.js)
docker/
  Dockerfile.frontend   # Multi-stage: Node build → nginx serve
  Dockerfile.backend    # Node.js production image
  nginx.conf            # nginx config (React Router + /api proxy for local dev)
  docker-compose.yml    # Local dev environment
terraform/
  bootstrap/        # Remote state backend (S3 + native locking)
  infrastructure/   # Main infra entrypoint (VPC + EKS + DNS + IRSA + ECR)
  modules/
    vpc/            # VPC with public/private subnets
    eks/            # EKS cluster + OIDC provider
    irsa/           # Reusable IAM role for service accounts
    dns/            # Route53 hosted zone
kubernetes/
  app/              # TaskBoard manifests (namespace: taskboard)
  argocd/           # ArgoCD Applications (app-of-apps)
  certmanager/      # ClusterIssuer (Let's Encrypt DNS-01)
  externaldns/      # (values in argocd apps)
docs/
  architecture.md   # Mermaid architecture diagram
.github/workflows/  # CI/CD pipelines
```

## Roadmap

| Phase | Work | Status |
|-------|------|--------|
| 0a | Bootstrap: S3 bucket (versioning, encryption, public access block) | ✅ written |
| 0b | Bootstrap: S3 native state locking (`use_lockfile = true`, Terraform ≥1.10) | ✅ written |
| 0c | Bootstrap: provider + version constraints (`terraform >= 1.10`, `aws ~> 5.0`) | ✅ written |
| 0d | Bootstrap: `terraform apply` to create the state bucket in AWS | ⬜ not applied |
| 1a | Infra: VPC module — VPC, 3 public + 3 private subnets, IGW, NAT GW, route tables | ✅ complete |
| 1b | Infra: `infrastructure/` version.tf — S3 backend + provider config | ✅ complete |
| 1c | Infra: `infrastructure/` variables.tf — region, project, env, CIDR, EKS version, domain | ✅ complete |
| 1d | Infra: EKS module — cluster, managed node groups, security groups, OIDC provider | ✅ complete |
| 1e | Infra: IRSA module — reusable IAM role for Kubernetes service accounts | ✅ complete |
| 1f | Infra: DNS module — Route53 hosted zone for `labs.virtualscale.dev` | ✅ complete |
| 1g | Infra: Wire EKS, IRSA, DNS into `infrastructure/main.tf` (VPC already wired) | ✅ complete |
| 1h | Infra: `infrastructure/outputs.tf` — expose cluster endpoint, OIDC, subnet IDs | ✅ complete |
| 1i | Infra: `terraform apply` to provision EKS cluster in AWS | ⬜ not applied |
| 2a | K8s add-ons: NGINX Ingress Controller (ArgoCD Application → Helm) | ✅ complete |
| 2b | K8s add-ons: CertManager + Let's Encrypt ClusterIssuer | ✅ complete |
| 2c | K8s add-ons: ExternalDNS (Route53) | ✅ complete |
| 2d | K8s add-ons: ArgoCD Applications (app-of-apps pattern) | ✅ complete |
| 3a | App: Plane app Kubernetes manifests + Ingress (TLS at `eks.labs.virtualscale.dev`) | ✅ complete |
| 3b | App: ArgoCD Application resource pointing to repo | ✅ complete |
| 4a | CI/CD Pipeline 1: Terraform (validate → Checkov scan → plan → apply) | ✅ complete |
| 4b | CI/CD Pipeline 2: Docker build → ECR push → Trivy scan → deploy to EKS | ✅ complete |
| 5  | Monitoring: Prometheus + Grafana (kube-prometheus-stack Helm chart + dashboards) | ✅ complete |
| 6  | Architecture diagram (Mermaid — `docs/architecture.md`) | ✅ complete |

## Current status (last updated: 2026-03-28)
- Bootstrap applied ✅ — S3 state bucket created
- Infrastructure applied ✅ — VPC, EKS, DNS, IRSA, ECR all live in AWS
- IRSA role ARNs + ECR URLs filled into K8s manifests ✅
- **Next:** fill remaining 3 placeholders (GitHub org, email, Grafana password), bootstrap ArgoCD, push Docker images

## Terraform apply — outputs and what was done with them

### Command run
```bash
cd terraform/infrastructure
terraform output
```

### Outputs received (2026-03-28)
```
cert_manager_role_arn    = "arn:aws:iam::207137402976:role/plane-app-eks-prod-cert-manager"
cluster_ca_certificate   = <sensitive>
cluster_endpoint         = "https://789F8A103F2701C1178E7820B77A4F15.gr7.eu-west-2.eks.amazonaws.com"
cluster_name             = "plane-app-eks-prod"
cluster_oidc_issuer_url  = "https://oidc.eks.eu-west-2.amazonaws.com/id/789F8A103F2701C1178E7820B77A4F15"
ecr_backend_url          = "207137402976.dkr.ecr.eu-west-2.amazonaws.com/plane-app-eks/plane-backend"
ecr_frontend_url         = "207137402976.dkr.ecr.eu-west-2.amazonaws.com/plane-app-eks/plane-frontend"
ecr_worker_url           = "207137402976.dkr.ecr.eu-west-2.amazonaws.com/plane-app-eks/plane-worker"
external_dns_role_arn    = "arn:aws:iam::207137402976:role/plane-app-eks-prod-external-dns"
hosted_zone_id           = "Z00879452B58B5U5DC0L8"
name_servers             = ["ns-1061.awsdns-04.org", "ns-1816.awsdns-35.co.uk", "ns-264.awsdns-33.com", "ns-536.awsdns-03.net"]
oidc_provider_arn        = "arn:aws:iam::207137402976:oidc-provider/oidc.eks.eu-west-2.amazonaws.com/id/789F8A103F2701C1178E7820B77A4F15"
private_subnet_ids       = ["subnet-01523f2e8138e2f70", "subnet-0d785a6be6719423c", "subnet-0d1f7c9b4b6653aea"]
public_subnet_ids        = ["subnet-0e23e1d2780d4ece7", "subnet-0cedea7f1c22439de", "subnet-0f5cdfde400ffbc6f"]
vpc_id                   = "vpc-0b30160a54b58ddf3"
```

### What was copied and where it was pasted

| Output value | Pasted into file | Field updated |
|---|---|---|
| `cert_manager_role_arn` | `kubernetes/argocd/apps/cert-manager.yaml` | `eks.amazonaws.com/role-arn` annotation |
| `external_dns_role_arn` | `kubernetes/argocd/apps/external-dns.yaml` | `eks.amazonaws.com/role-arn` annotation |
| `ecr_frontend_url` + `:latest` | `kubernetes/app/plane-web.yaml` | `image:` field on the frontend Deployment |
| `ecr_backend_url` + `:latest` | `kubernetes/app/plane-api.yaml` | `image:` field on the backend Deployment |
| `ecr_backend_url` + `:latest` | `kubernetes/app/plane-worker.yaml` | `image:` field on the db-migrate Job |
| `name_servers` (all 4) | DNS registrar for `virtualscale.dev` | NS records delegating `labs.virtualscale.dev` to Route53 |

### Values not yet used (pending)
| Output value | Will be used for |
|---|---|
| `cluster_name` | `aws eks update-kubeconfig --name plane-app-eks-prod` |
| `cluster_endpoint` | kubectl / ArgoCD connection |
| `ecr_worker_url` | Not needed — worker ECR repo exists but no separate worker image in TaskBoard |

## Remaining placeholders (3 still to fill)
| File | Placeholder | Value needed |
|---|---|---|
| `kubernetes/argocd/apps/plane.yaml` | ~~`REPLACE_WITH_YOUR_GITHUB_ORG`~~ | ✅ set to `Mik3asg` |
| `kubernetes/argocd/apps/monitoring.yaml` | ~~`REPLACE_WITH_GRAFANA_PASSWORD`~~ | ✅ set |
| `kubernetes/certmanager/cluster-issuer.yaml` | ~~`REPLACE_WITH_YOUR_EMAIL`~~ | ✅ set to `mickael.devops@gmail.com` |

## GitHub Actions secrets (set in repo Settings → Secrets)
| Secret name | Value |
|---|---|
| `AWS_TERRAFORM_ROLE_ARN` | IAM role ARN for GitHub OIDC (create manually — see below) |
| `AWS_CICD_ROLE_ARN` | Same role or separate one with ECR + EKS access |
| `ECR_REGISTRY` | `207137402976.dkr.ecr.eu-west-2.amazonaws.com` |
| `ARGOCD_SERVER` | ArgoCD hostname (available after ArgoCD install) |
| `ARGOCD_TOKEN` | ArgoCD API token (generated in ArgoCD UI) |

## Key concepts

### IRSA — IAM Roles for Service Accounts
By default, every pod on a node inherits the node's IAM role. That's a security problem — a compromised pod could access any AWS resource the node can touch. IRSA fixes this by giving each Kubernetes **service account** its own dedicated IAM role, so a pod only gets the exact AWS permissions it needs and nothing more.

How it works:
1. Kubernetes injects a short-lived JWT token into the pod (via a projected volume)
2. The pod presents that token to AWS STS (`AssumeRoleWithWebIdentity`)
3. AWS validates the token against the **OIDC provider** (registered in the EKS module)
4. STS returns temporary credentials scoped to the IAM role

The IRSA Terraform module is **reusable** — called once per component with three inputs: the OIDC provider ARN, the Kubernetes namespace + service account name, and the IAM policy to attach. Used by:
- **ExternalDNS** — needs Route53 `ChangeResourceRecordSets` permission
- **cert-manager** — needs Route53 access for DNS-01 ACME challenges
- **AWS Load Balancer Controller** (if used) — needs EC2/ELB permissions

### OIDC Provider
OpenID Connect provider registered in AWS IAM that acts as a trust bridge between Kubernetes and AWS STS. Set up once per EKS cluster (done in the EKS module). Without it, IRSA cannot work.

### ExternalDNS
Watches Kubernetes Ingress resources and automatically creates/updates Route53 DNS records to match. When you deploy the Plane app with an Ingress pointing to `eks.labs.virtualscale.dev`, ExternalDNS creates that A record in Route53 automatically — no manual DNS management needed.

### cert-manager
Watches Kubernetes Ingress resources annotated with a ClusterIssuer and automatically requests TLS certificates from Let's Encrypt. Uses the DNS-01 ACME challenge (via ExternalDNS + Route53) to prove domain ownership. Certificates auto-renew before expiry.

### ArgoCD (GitOps)
Runs inside the cluster and continuously syncs cluster state from this Git repo. When you push a change to a Kubernetes manifest, ArgoCD detects the diff and applies it automatically — Git becomes the single source of truth for what runs in the cluster.

## Notes
- Target URL: `https://eks.labs.virtualscale.dev`
- AWS region: `eu-west-2`
- EKS version: `1.32`
- No DynamoDB for state locking — using S3 native locking (`use_lockfile = true`)
- Update roadmap status emojis and "Current status" as work progresses
