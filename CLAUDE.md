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
| 0d | Bootstrap: `terraform apply` to create the state bucket in AWS | ✅ applied |
| 1a | Infra: VPC module — VPC, 3 public + 3 private subnets, IGW, NAT GW, route tables | ✅ complete |
| 1b | Infra: `infrastructure/` version.tf — S3 backend + provider config | ✅ complete |
| 1c | Infra: `infrastructure/` variables.tf — region, project, env, CIDR, EKS version, domain | ✅ complete |
| 1d | Infra: EKS module — cluster, managed node groups, security groups, OIDC provider | ✅ complete |
| 1e | Infra: IRSA module — reusable IAM role for Kubernetes service accounts | ✅ complete |
| 1f | Infra: DNS module — Route53 hosted zone for `labs.virtualscale.dev` | ✅ complete |
| 1g | Infra: Wire EKS, IRSA, DNS into `infrastructure/main.tf` (VPC already wired) | ✅ complete |
| 1h | Infra: `infrastructure/outputs.tf` — expose cluster endpoint, OIDC, subnet IDs | ✅ complete |
| 1i | Infra: `terraform apply` to provision EKS cluster in AWS | ✅ applied |
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
- All placeholders filled in K8s manifests ✅
- Cloudflare NS records added for `labs.virtualscale.dev` delegation ✅
- ArgoCD installed and all Applications applied ✅
- EBS CSI driver installed ✅ (unblocks monitoring PVC provisioning)
- external-dns chart switched from Bitnami → kubernetes-sigs ✅
- Docker Desktop launched and verified ✅
- `package-lock.json` generated for frontend and backend ✅ (unblocks Docker builds)
- LoadBalancer subnet tag bug fixed ✅ — both NGINX and ArgoCD now have external hostnames
- GitHub Actions IAM roles created (github-actions-terraform, github-actions-cicd) ✅
- GitHub OIDC provider registered in AWS IAM ✅
- ArgoCD token generated ✅
- GitHub Actions secrets configured in repo ✅
- Docker images pushed to ECR ✅
- Code pushed to GitHub ✅
- All taskboard pods Running ✅ (frontend, backend, postgres, redis, db-migrate Completed)
- TLS certificate issued by Let's Encrypt ✅
- DNS record created by ExternalDNS in Route53 ✅
- **App live at https://eks.labs.virtualscale.dev** ✅

## Deployment steps log

### Step 1 — Connect kubectl to EKS
```bash
aws eks update-kubeconfig --region eu-west-2 --name plane-app-eks-prod
kubectl get nodes   # verify 1 node in Ready state
```

### Step 2 — Install ArgoCD
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=180s
```

### Step 3 — Apply ArgoCD Applications + ClusterIssuer
```bash
kubectl apply -f kubernetes/argocd/apps/
kubectl apply -f kubernetes/certmanager/cluster-issuer.yaml
```
This triggers ArgoCD to deploy: ingress-nginx, cert-manager, external-dns, taskboard, monitoring.

### Step 4 — Install EBS CSI driver (done after monitoring pods were stuck Pending)
```bash
aws iam attach-role-policy \
  --role-name plane-app-eks-prod-eks-node-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --region eu-west-2

aws eks create-addon \
  --cluster-name plane-app-eks-prod \
  --addon-name aws-ebs-csi-driver \
  --region eu-west-2
```

### Step 5 — Generate package-lock.json files (required for Docker builds)
The `npm ci` command used in the Dockerfiles requires lock files to be present. Run once locally before building images:
```bash
cd app/frontend && npm install && cd ../..
cd app/backend  && npm install && cd ../..
```
Both `app/frontend/package-lock.json` and `app/backend/package-lock.json` must be committed to the repo so the Docker build context includes them.

### Step 6 — Push Docker images to ECR
Prerequisites: Docker Desktop running (`docker info` returns successfully), lock files generated (Step 5).
```bash
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin 207137402976.dkr.ecr.eu-west-2.amazonaws.com

docker build -f docker/Dockerfile.frontend \
  -t 207137402976.dkr.ecr.eu-west-2.amazonaws.com/plane-app-eks/plane-frontend:latest .
docker push 207137402976.dkr.ecr.eu-west-2.amazonaws.com/plane-app-eks/plane-frontend:latest

docker build -f docker/Dockerfile.backend \
  -t 207137402976.dkr.ecr.eu-west-2.amazonaws.com/plane-app-eks/plane-backend:latest .
docker push 207137402976.dkr.ecr.eu-west-2.amazonaws.com/plane-app-eks/plane-backend:latest
```

### Step 7 — Push code to GitHub
```bash
git add .
git commit -m "feat: complete project setup with TaskBoard custom app"
git push origin main
```
ArgoCD will auto-sync the taskboard namespace once the repo is pushed and ECR images are available.

### Step 8 — Configure GitHub Actions secrets
In the GitHub repo: Settings → Secrets and variables → Actions → New repository secret.

| Secret name | Value |
|---|---|
| `AWS_TERRAFORM_ROLE_ARN` | IAM role ARN for GitHub OIDC (Terraform pipeline) |
| `AWS_CICD_ROLE_ARN` | IAM role ARN for GitHub OIDC (app CI/CD pipeline) |
| `ECR_REGISTRY` | `207137402976.dkr.ecr.eu-west-2.amazonaws.com` |
| `ARGOCD_SERVER` | ArgoCD server hostname (get with `kubectl get svc -n argocd argocd-server`) |
| `ARGOCD_TOKEN` | ArgoCD API token (Settings → Accounts → Generate token in ArgoCD UI) |

### Step 9 — Verify end-to-end
```bash
# All pods healthy
kubectl get pods -A

# Cert issued
kubectl get certificate -n taskboard

# DNS resolves
nslookup eks.labs.virtualscale.dev

# App reachable
curl -I https://eks.labs.virtualscale.dev
```

## Issues encountered and resolved

### Issue 1 — monitoring pods stuck in Pending
**Symptom:** All monitoring namespace pods (`prometheus`, `grafana`, `kube-state-metrics`, `node-exporter`) showed `Pending` status indefinitely after ArgoCD deployed the kube-prometheus-stack.

**Root cause:** Prometheus requires a PersistentVolumeClaim (5Gi). EKS does not install the EBS CSI driver by default — without it there is no StorageClass capable of provisioning EBS volumes, so PVCs remain unbound and pods cannot be scheduled.

**Fix:**
```bash
# Attach the required IAM policy to the node role
aws iam attach-role-policy \
  --role-name plane-app-eks-prod-eks-node-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --region eu-west-2

# Install the EBS CSI driver as a managed EKS add-on
aws eks create-addon \
  --cluster-name plane-app-eks-prod \
  --addon-name aws-ebs-csi-driver \
  --region eu-west-2
```

**Prevention:** Add `aws_eks_addon` resource for `aws-ebs-csi-driver` to the EKS Terraform module so it is provisioned automatically on future clusters.

---

### Issue 2 — external-dns pod in ImagePullBackOff
**Symptom:** `external-dns` pod stuck in `ImagePullBackOff`. Event log showed:
```
Back-off pulling image "docker.io/bitnami/external-dns:0.14.0-debian-12-r16"
```

**Root cause:** The Bitnami Helm chart pulls images from Docker Hub (`docker.io/bitnami/...`). Docker Hub enforces rate limits on anonymous pulls from shared IPs (common on cloud VMs/EKS nodes). The pull was being throttled and eventually timing out.

**Fix:** Switched the ArgoCD Application from the Bitnami chart to the official `kubernetes-sigs/external-dns` chart, which pulls images from a registry without rate limits:
```yaml
repoURL: https://kubernetes-sigs.github.io/external-dns/
chart: external-dns
targetRevision: 1.14.5
```
Then re-applied: `kubectl apply -f kubernetes/argocd/apps/external-dns.yaml`

**Prevention:** Prefer `kubernetes-sigs` or public ECR (`public.ecr.aws`) hosted charts over Bitnami for EKS workloads to avoid Docker Hub rate limiting.

---

### Issue 3 — taskboard namespace empty (no pods)
**Symptom:** ArgoCD showed taskboard as `Synced / Healthy` but `kubectl get pods -n taskboard` returned `No resources found`.

**Root cause:** Two sub-causes:
1. The Git repo (`https://github.com/Mik3asg/plane-app-aws-eks`) had not been pushed — ArgoCD pointed at a remote repo that didn't contain the manifests yet.
2. The ECR images (`plane-frontend:latest`, `plane-backend:latest`) had not been built and pushed — even once the manifests are applied, pods would enter `ImagePullBackOff`.

**Fix (in progress):**
1. Push the repo: `git push origin main`
2. Build and push Docker images to ECR (blocked by Docker Desktop not running — see Issue 4)

---

### Issue 4 — Docker build failing (Docker Desktop not running)
**Symptom:** Running `docker build` returned:
```
ERROR: open //./pipe/dockerDesktopLinuxEngine: The system cannot find the file specified.
```

**Root cause:** Docker Desktop was not started on the Windows machine. The Docker CLI could not connect to the Linux engine daemon (`dockerDesktopLinuxEngine` named pipe).

**Fix:** Launch Docker Desktop from the Start menu. Wait for the whale icon in the system tray to stop animating (fully started), then open a new terminal and retry. Verify with `docker info` before building.

**Prevention:** Always verify `docker info` returns successfully before running build commands.

---

### Issue 5 — Docker build failing (missing package-lock.json)
**Symptom:** Docker build failed during `npm ci` with:
```
npm error The `npm ci` command can only install with an existing package-lock.json or
npm error npm-shrinkwrap.json with lockfileVersion >= 1.
```

**Root cause:** `npm ci` (used in the Dockerfiles for reproducible installs) requires a `package-lock.json` to exist. The lock files for `app/frontend` and `app/backend` had not been generated — only `package.json` was committed.

**Fix:** Run `npm install` locally in each app directory to generate the lock files, then commit them:
```bash
cd app/frontend && npm install && cd ../..
cd app/backend  && npm install && cd ../..
git add app/frontend/package-lock.json app/backend/package-lock.json
git commit -m "chore: add package-lock.json for frontend and backend"
```

**Prevention:** Always run `npm install` and commit the resulting `package-lock.json` whenever a new `package.json` is created. The Dockerfile should use `npm ci` (not `npm install`) for deterministic, CI-safe dependency installs.

---

### Issue 6 — LoadBalancer services stuck in `<pending>` (EXTERNAL-IP never assigned)
**Symptom:** Both `ingress-nginx-controller` and `argocd-server` services showed `TYPE: LoadBalancer` but `EXTERNAL-IP: <pending>` indefinitely (5+ hours). Attaching `ElasticLoadBalancingFullAccess` to the node role had no effect.

Checking the service events revealed the exact error:
```
kubectl describe svc ingress-nginx-controller -n ingress-nginx | tail -20

Warning  SyncLoadBalancerFailed  service-controller  Error syncing load balancer:
failed to ensure load balancer: could not find any suitable subnets for creating the ELB
```

**Root cause:** The EKS Cloud Controller Manager (CCM) looks for subnets tagged with both:
- `kubernetes.io/role/elb: 1` — marks subnet as eligible for internet-facing load balancers
- `kubernetes.io/cluster/<cluster-name>: shared` — scopes the subnet to the specific cluster

The VPC module had the correct tags in Terraform, but the `cluster_name` passed to the VPC module in `infrastructure/main.tf` was wrong:
```hcl
# Bug — passes "plane-app-eks" (project name only)
cluster_name = var.project_name

# Correct — must include environment suffix to match actual cluster name "plane-app-eks-prod"
cluster_name = "${var.project_name}-${var.environment}"
```

This meant the subnets were tagged `kubernetes.io/cluster/plane-app-eks: shared` instead of `kubernetes.io/cluster/plane-app-eks-prod: shared`. The CCM could not match the subnets to the cluster and refused to provision any ELB.

**Fix — two parts:**

1. Tag the subnets immediately in AWS (no need to re-run Terraform):
```bash
aws ec2 create-tags --resources subnet-0e23e1d2780d4ece7 --tags Key=kubernetes.io/cluster/plane-app-eks-prod,Value=shared --region eu-west-2
aws ec2 create-tags --resources subnet-0cedea7f1c22439de --tags Key=kubernetes.io/cluster/plane-app-eks-prod,Value=shared --region eu-west-2
aws ec2 create-tags --resources subnet-0f5cdfde400ffbc6f --tags Key=kubernetes.io/cluster/plane-app-eks-prod,Value=shared --region eu-west-2
```

2. Fix the Terraform code so the tag is correct on future `terraform apply` runs:
```hcl
# terraform/infrastructure/main.tf — module "vpc" block
cluster_name = "${var.project_name}-${var.environment}"
```

Within ~90 seconds of the tags being applied, the CCM retried and both load balancers provisioned successfully:
```
Normal  EnsuredLoadBalancer  service-controller  Ensured load balancer
```

**Prevention:** Always pass `"${var.project_name}-${var.environment}"` as the `cluster_name` to the VPC module — it must exactly match the EKS cluster name. Verify subnet tags with:
```bash
aws ec2 describe-subnets \
  --subnet-ids <public-subnet-ids> \
  --query 'Subnets[*].Tags[?starts_with(Key, `kubernetes.io`)]' \
  --region eu-west-2
```

### Issue 7 — All pods stuck in Pending: node pod limit reached
**Symptom:** All taskboard, monitoring, ingress-nginx, and external-dns pods showed `Pending` indefinitely. CPU and memory were not the bottleneck (node was only at 30% CPU / 26% memory). Describing a pending pod revealed:
```
Warning  FailedScheduling  default-scheduler
0/1 nodes are available: 1 Too many pods.
preemption: 0/1 nodes are available: 1 No preemption victims found for incoming pod.
```

Cluster state at time of issue:
- Nodes: 1 × `t3.medium`
- Pods scheduled on node: 18 (`kubectl get pods -A --field-selector spec.nodeName!="" | wc -l`)
- Pod limit for t3.medium: 17 (EKS VPC CNI hard limit based on ENI × IPs per ENI)

**Root cause:** EKS uses the AWS VPC CNI plugin which assigns a real VPC IP address to every pod. The number of pods per node is capped by the instance's ENI and IP limits. For `t3.medium`:
- 3 network interfaces × (6 IPs per interface - 1) + 2 = **17 pods maximum**

With ArgoCD (~8 pods), kube-system (~6 pods), cert-manager, and other add-ons already running, the node was full before the taskboard and monitoring workloads could be scheduled.

**Fix options (choose one):**

**Option A — Scale to 2 nodes (simplest, ~$1/day extra cost):**
```bash
aws eks update-nodegroup-config \
  --cluster-name plane-app-eks-prod \
  --nodegroup-name plane-app-eks-prod-nodes \
  --scaling-config minSize=1,maxSize=2,desiredSize=2 \
  --region eu-west-2
```
Scale back to 1 after testing to reduce cost:
```bash
aws eks update-nodegroup-config \
  --cluster-name plane-app-eks-prod \
  --nodegroup-name plane-app-eks-prod-nodes \
  --scaling-config minSize=1,maxSize=2,desiredSize=1 \
  --region eu-west-2
```

**Option B — Enable prefix delegation on VPC CNI (free, increases pod limit to 110):**
Prefix delegation assigns /28 IPv4 prefixes to ENIs instead of individual IPs, dramatically increasing the pod limit without adding nodes:
```bash
kubectl set env daemonset aws-node -n kube-system \
  ENABLE_PREFIX_DELEGATION=true \
  WARM_PREFIX_TARGET=1
```
Then restart the node for the new limit to take effect.

**Option C — Use a larger instance type (higher cost):**
Larger instances have more ENIs and IPs. `t3.large` supports 35 pods, `t3.xlarge` supports 58 pods. Requires recreating the node group in Terraform.

**Prevention:** When planning EKS clusters with many add-ons (ArgoCD, cert-manager, ingress-nginx, monitoring, external-dns), account for system pod overhead. With a full add-on stack, a single `t3.medium` can be exhausted before any application pods are scheduled. Use Option B (prefix delegation) or size for at least 2 nodes from the start.

---

### Issue 8 — ArgoCD token generation failed (apiKey capability not enabled)
**Symptom:** Running `argocd account generate-token --account admin` returned:
```
rpc error: code = Unknown desc = failed to update account with new token:
account 'admin' does not have apiKey capability
```

**Root cause:** By default the ArgoCD `admin` account only has `login` capability. The `apiKey` capability (required to generate API tokens for CI/CD use) is not enabled unless explicitly configured in the `argocd-cm` ConfigMap.

**Fix:** Patch the `argocd-cm` ConfigMap to add `apiKey` to the admin account's capabilities:
```bash
kubectl patch configmap argocd-cm -n argocd \
  --type merge \
  -p '{"data": {"accounts.admin": "apiKey, login"}}'
```

Then regenerate the token:
```bash
./argocd.exe account generate-token --account admin
```

**Prevention:** When installing ArgoCD for use with CI/CD pipelines, patch `argocd-cm` immediately after install to enable `apiKey` capability before attempting token generation.

---

### Issue 9 — argocd CLI not found in Git Bash on Windows
**Symptom:** `argocd: command not found` in Git Bash. Standard install paths (`/usr/local/bin`, `/usr/bin`) either don't exist or are permission-denied in Git Bash on Windows.

**Fix:** Download the Windows binary directly to the project directory and run it with `./`:
```bash
curl -sSL -o argocd.exe https://github.com/argoproj/argo-cd/releases/latest/download/argocd-windows-amd64.exe
./argocd.exe login localhost:8080 --username admin --password <password> --insecure
./argocd.exe account generate-token --account admin
```

**Prevention:** On Windows with Git Bash, always use `./argocd.exe` from a local directory rather than trying to install to system paths.

---

### Issue 10 — postgres PVC stuck in Pending (no StorageClass)
**Symptom:** `kubectl get pvc -n taskboard` showed the `postgres-pvc` in `Pending` state indefinitely. Describing the PVC showed no provisioner was triggered.

**Root cause:** The PVC manifest had no `storageClassName` field. Without an explicit storage class, EKS does not automatically provision an EBS volume — the default StorageClass on EKS requires the EBS CSI driver and explicit class reference.

**Fix:** Added `storageClassName: gp2` to the PVC spec in `kubernetes/app/postgres.yaml`:
```yaml
spec:
  storageClassName: gp2
```

**Prevention:** Always specify `storageClassName: gp2` (or `gp3`) explicitly on PVCs in EKS manifests. Never rely on implicit default StorageClass resolution.

---

### Issue 11 — postgres pod CrashLoopBackOff (EBS volume has lost+found at root)
**Symptom:** After the postgres PVC was provisioned, the postgres pod went into `CrashLoopBackOff`. Container logs showed PostgreSQL refusing to start because the data directory `/var/lib/postgresql/data` was not empty — it contained a `lost+found` directory created by the EBS volume's ext4 filesystem.

**Root cause:** EBS volumes are formatted with ext4, which creates a `lost+found` directory at the filesystem root. The postgres container mounts the volume directly at its data directory and refuses to initialise if any files already exist there.

**Fix:** Added `subPath: postgres` to the volumeMount in `kubernetes/app/postgres.yaml`:
```yaml
volumeMounts:
  - name: postgres-data
    mountPath: /var/lib/postgresql/data
    subPath: postgres      # postgres data goes into a subdirectory, avoiding lost+found
```
This causes Kubernetes to mount only the `postgres/` subdirectory of the EBS volume, bypassing `lost+found`.

**Prevention:** Always use `subPath` when mounting EBS-backed PVCs into containers that require an empty directory (databases, etc.).

---

### Issue 12 — IRSA trust policy typo (`serviceaccounts` vs `serviceaccount`)
**Symptom:** cert-manager pod had IRSA credentials but Route53 calls returned `AccessDenied`. Inspecting the IAM role trust policy showed the `sub` condition contained `system:serviceaccounts:cert-manager:cert-manager` (plural) instead of `system:serviceaccount:cert-manager:cert-manager` (singular).

**Root cause:** Kubernetes OIDC tokens use `system:serviceaccount:<namespace>:<name>` (singular) in the `sub` claim. The IRSA module had a hard-coded `system:serviceaccounts:` prefix (plural), causing the `StringEquals` condition to never match — AWS STS rejected all `AssumeRoleWithWebIdentity` calls.

**Fix:** Corrected the typo in `terraform/modules/irsa/main.tf`:
```hcl
# Before (wrong)
"${local.oidc_issuer_bare}:sub" = "system:serviceaccounts:${var.namespace}:${var.service_account_name}"

# After (correct)
"${local.oidc_issuer_bare}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
```
Then ran `terraform apply` to update the trust policies for both the cert-manager and external-dns roles.

**Prevention:** The correct singular form is `system:serviceaccount:` — verify this in any IRSA trust policy. After applying Terraform, always check the generated trust policy in the IAM console before testing.

---

### Issue 13 — Prometheus PVC stuck in Pending (missing StorageClass in Helm values)
**Symptom:** After fixing the EBS CSI driver, Prometheus remained `Pending`. The PVC `prometheus-kube-prometheus-stack-prometheus-db-...` had no `STORAGECLASS` column in `kubectl get pvc -n monitoring`.

**Root cause:** The kube-prometheus-stack Helm values in `kubernetes/argocd/apps/monitoring.yaml` specified a `volumeClaimTemplate` under `storageSpec` but omitted `storageClassName`. Without it, the StatefulSet PVC template had no storage class and the EBS CSI provisioner was never triggered.

**Fix:** Added `storageClassName: gp2` to the Prometheus `storageSpec` in `monitoring.yaml`:
```yaml
storageSpec:
  volumeClaimTemplate:
    spec:
      storageClassName: gp2
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 5Gi
```

Because `volumeClaimTemplates` on StatefulSets are immutable, the old StatefulSet and PVC had to be deleted before ArgoCD could re-create them with the corrected spec:
```bash
kubectl delete statefulset prometheus-kube-prometheus-stack-prometheus -n monitoring
kubectl delete pvc prometheus-kube-prometheus-stack-prometheus-db-... -n monitoring
# ArgoCD auto-reconciles and recreates with the correct StorageClass
```

**Prevention:** Always include `storageClassName: gp2` in any Helm values that define `volumeClaimTemplate`. When updating StatefulSet PVC templates, remember they are immutable — always delete the StatefulSet and PVC before re-applying.

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
