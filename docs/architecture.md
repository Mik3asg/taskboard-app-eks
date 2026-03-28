# Architecture Diagram

```mermaid
graph TB
    User([User Browser])
    GH([GitHub Repo])

    subgraph AWS["AWS — eu-west-2"]
        R53[Route53\nlabs.virtualscale.dev]
        ECR[ECR\nplane images]

        subgraph VPC["VPC  10.0.0.0/16"]

            subgraph PublicSubnets["Public Subnets ×3"]
                NLB[Network\nLoad Balancer]
            end

            subgraph PrivateSubnets["Private Subnets ×3"]
                NAT[NAT Gateway]

                subgraph EKS["EKS Cluster  v1.32"]
                    NGINX[NGINX Ingress\nController]

                    subgraph PlaneNS["namespace: plane"]
                        Web[plane-web\nNext.js :3000]
                        API[plane-api\nDjango :8000]
                        Worker[plane-worker\nCelery]
                        PG[(PostgreSQL)]
                        RD[(Redis)]
                    end

                    subgraph AddOns["Add-ons"]
                        CM[cert-manager]
                        EDNS[ExternalDNS]
                        ARGO[ArgoCD]
                    end

                    subgraph Monitoring["namespace: monitoring"]
                        PROM[Prometheus]
                        GRAF[Grafana]
                    end
                end
            end
        end

        subgraph IAM["IAM  IRSA"]
            RoleCM[cert-manager role\nRoute53 DNS-01]
            RoleEDNS[external-dns role\nRoute53 ChangeRecordSets]
        end

        S3[S3\nTerraform state]
    end

    User -->|HTTPS eks.labs.virtualscale.dev| R53
    R53 -->|A record| NLB
    NLB --> NGINX
    NGINX -->|/| Web
    NGINX -->|/api /auth| API
    API --> PG
    API --> RD
    Worker --> PG
    Worker --> RD

    CM -->|DNS-01 challenge| R53
    CM -.->|assumes via OIDC| RoleCM
    EDNS -->|upsert A record| R53
    EDNS -.->|assumes via OIDC| RoleEDNS

    GH -->|push triggers| ARGO
    ARGO -->|reconciles| PlaneNS
    ARGO -->|reconciles| AddOns

    GH -->|CI: build+push| ECR
    ECR -.->|pull images| EKS

    PROM -->|scrapes metrics| EKS
    GRAF -->|queries| PROM

    PrivateSubnets -->|outbound via| NAT
```

## Component responsibilities

| Component | What it does |
|---|---|
| **Route53** | Authoritative DNS for `labs.virtualscale.dev` |
| **NLB** | AWS Network Load Balancer provisioned by NGINX Ingress; entry point for all HTTPS traffic |
| **NGINX Ingress** | Terminates TLS, routes requests to plane-web or plane-api by path |
| **cert-manager** | Requests and renews Let's Encrypt TLS certificates via Route53 DNS-01 challenge |
| **ExternalDNS** | Watches Ingress resources and creates/updates Route53 A records automatically |
| **ArgoCD** | GitOps controller — syncs cluster state from this Git repo on every push |
| **Prometheus** | Scrapes metrics from all cluster workloads and nodes |
| **Grafana** | Dashboards for CPU/memory, pod health, node status, and Ingress traffic |
| **IRSA** | Grants cert-manager and ExternalDNS scoped Route53 access via Kubernetes OIDC tokens |
| **ECR** | Private image registry; CI pipeline pushes versioned Plane images here |
| **S3** | Remote Terraform state backend with native locking (`use_lockfile = true`) |
