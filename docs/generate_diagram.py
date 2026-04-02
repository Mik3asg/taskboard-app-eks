"""
Architecture diagram — plane-app-aws-eks
All connectors: dotted lines, orthogonal routing, white-bg labels.
"""
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch

fig, ax = plt.subplots(figsize=(26, 18))
ax.set_xlim(0, 26)
ax.set_ylim(0, 18)
ax.axis('off')
fig.patch.set_facecolor('#F0F4F8')

LS = (0, (6, 3))   # dotted dash pattern for ax.plot lines

# ── primitives ────────────────────────────────────────────────────────────────
def box(ax, x, y, w, h, fc, label='', fs=8, tc='white', bold=False, alpha=0.93, r=0.18):
    ax.add_patch(FancyBboxPatch((x, y), w, h,
        boxstyle=f"round,pad=0,rounding_size={r}",
        facecolor=fc, edgecolor='white', linewidth=1.2, alpha=alpha, zorder=3))
    if label:
        ax.text(x+w/2, y+h/2, label, ha='center', va='center',
                fontsize=fs, color=tc, fontweight='bold' if bold else 'normal', zorder=4)

def frame(ax, x, y, w, h, ec, label='', fs=8.5, lw=2.0, ls='-'):
    ax.add_patch(FancyBboxPatch((x, y), w, h,
        boxstyle="round,pad=0,rounding_size=0.25",
        facecolor='none', edgecolor=ec, linewidth=lw, linestyle=ls, zorder=2))
    if label:
        ax.text(x+0.22, y+h-0.28, label, ha='left', va='top',
                fontsize=fs, color=ec, fontweight='bold', zorder=4)

def lbl(ax, x, y, text, color, fs=6.7, ha='center', va='center'):
    """Label with white background — never obscured by lines."""
    ax.text(x, y, text, ha=ha, va=va, fontsize=fs, color=color,
            style='italic', zorder=9,
            bbox=dict(facecolor='white', edgecolor='none', alpha=0.9, pad=2.0))

def line(ax, xs, ys, color, lw=1.5):
    """Dotted polyline, no arrowhead."""
    ax.plot(xs, ys, color=color, lw=lw, linestyle=LS, zorder=5,
            solid_capstyle='round')

def arrow_at(ax, x1, y1, x2, y2, color, lw=1.5, bidir=False):
    """Small arrowhead drawn on top of the last segment (x1,y1)→(x2,y2)."""
    style = '<->' if bidir else '->'
    ax.annotate('', xy=(x2, y2), xytext=(x1, y1),
        arrowprops=dict(arrowstyle=style, color=color, lw=lw,
                        connectionstyle='arc3,rad=0'), zorder=7)

def connector(ax, pts, color, lw=1.5, bidir=False):
    """
    Draw a dotted polyline through pts and add an arrowhead on the last segment.
    pts = list of (x, y) tuples, at least 2.
    """
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    line(ax, xs, ys, color, lw)
    arrow_at(ax, pts[-2][0], pts[-2][1], pts[-1][0], pts[-1][1], color, lw, bidir)

# ═══════════════════════════════════════════════════════════════════════════════
# TITLE
# ═══════════════════════════════════════════════════════════════════════════════
ax.text(13, 17.6, 'TaskBoard — AWS EKS Architecture',
        ha='center', fontsize=17, fontweight='bold', color='#263238')
ax.text(13, 17.15, 'plane-app-aws-eks  ·  eu-west-2  ·  https://eks.labs.virtualscale.dev',
        ha='center', fontsize=9.5, color='#546E7A')

# ═══════════════════════════════════════════════════════════════════════════════
# TOP-LEFT — External actors  (x 0.3–4.2, y 12.2–16.8)
# ═══════════════════════════════════════════════════════════════════════════════
frame(ax, 0.3, 12.2, 3.9, 4.6, '#37474F', 'External / CI', fs=8)
box(ax, 0.55, 15.8, 3.4, 0.78, '#1565C0', 'User Browser',        fs=9,   bold=True)
box(ax, 0.55, 14.8, 3.4, 0.78, '#F57F17', 'Cloudflare DNS',      fs=9,   bold=True)
box(ax, 0.55, 13.8, 3.4, 0.78, '#2E7D32', 'GitHub Actions',      fs=9,   bold=True)
box(ax, 0.55, 12.5, 3.4, 1.0,  '#6A1B9A', "Let's Encrypt\n(ACME DNS-01)", fs=8.5, bold=True)

# ═══════════════════════════════════════════════════════════════════════════════
# TOP-RIGHT — AWS Global Services  (x 4.4–25.7, y 12.2–16.8)
# ═══════════════════════════════════════════════════════════════════════════════
frame(ax, 4.4, 12.2, 21.3, 4.6, '#FF6F00', 'AWS Global Services', fs=8.5)
box(ax, 4.65,  15.5, 3.2, 1.0, '#FF6F00', 'Route 53\nlabs.virtualscale.dev', fs=8.2)
box(ax, 8.15,  15.5, 3.2, 1.0, '#E65100', 'ECR\nplane-{frontend,backend}',   fs=8)
box(ax, 11.65, 15.5, 3.2, 1.0, '#BF360C', 'S3\nTerraform state',             fs=8.2)
box(ax, 15.15, 15.5, 3.2, 1.0, '#8D6E63', 'IAM / IRSA\nOIDC provider',       fs=8.2)
box(ax, 18.65, 15.5, 6.9, 1.0, '#6D4C41',
    'GitHub OIDC  →  github-actions-terraform  &  github-actions-cicd', fs=8)
box(ax, 4.65, 12.45, 20.9, 2.8, '#FFF3E0',
    'cert-manager IRSA role  (Route53: ChangeResourceRecordSets)\n'
    'external-dns IRSA role   (Route53: ChangeResourceRecordSets + ListHostedZones)\n'
    'github-actions-terraform role  (Terraform plan / apply)\n'
    'github-actions-cicd role  (ECR push + EKS deploy)',
    fs=7.8, tc='#5D4037', alpha=0.65)

# ═══════════════════════════════════════════════════════════════════════════════
# VPC  (x 0.3–25.7, y 0.3–12.0)
# ═══════════════════════════════════════════════════════════════════════════════
frame(ax, 0.3, 0.3, 25.4, 11.7, '#0288D1', 'AWS VPC  10.0.0.0/16  —  eu-west-2', fs=9, lw=2.5)

AZ_CFG = [
    ('eu-west-2a', 0.55,  '#0288D1', '#E3F2FD'),
    ('eu-west-2b', 8.85,  '#2E7D32', '#E8F5E9'),
    ('eu-west-2c', 17.15, '#F57F17', '#FFF8E1'),
]
AZ_W = 7.9

for az_lbl, ax_x, border, fill in AZ_CFG:
    ax.add_patch(FancyBboxPatch((ax_x, 0.55), AZ_W, 11.1,
        boxstyle="round,pad=0,rounding_size=0.2",
        facecolor=fill, edgecolor=border, linewidth=2, alpha=0.3, zorder=0))
    ax.text(ax_x+AZ_W/2, 11.48, az_lbl, ha='center', va='center',
            fontsize=9.5, color=border, fontweight='bold', zorder=2)

    # Public subnet
    pub_y = 9.75
    ax.add_patch(FancyBboxPatch((ax_x+0.2, pub_y), AZ_W-0.4, 1.5,
        boxstyle="round,pad=0,rounding_size=0.15",
        facecolor='#B3E5FC', edgecolor='#0288D1', linewidth=1.2, alpha=0.7, zorder=1))
    ax.text(ax_x+0.4, pub_y+1.3, 'Public subnet', ha='left', va='top',
            fontsize=7, color='#01579B', fontweight='bold', zorder=2)
    box(ax, ax_x+0.4,  pub_y+0.1, 3.1, 0.9, '#0288D1', 'NLB (NGINX Ingress)',   fs=7.8)
    box(ax, ax_x+3.75, pub_y+0.1, 3.95,0.9, '#0277BD', 'NAT Gateway → Internet',fs=7.8)

    # Private subnet
    prv_y = 0.75
    ax.add_patch(FancyBboxPatch((ax_x+0.2, prv_y), AZ_W-0.4, 8.75,
        boxstyle="round,pad=0,rounding_size=0.15",
        facecolor='#E8EAF6', edgecolor='#3949AB', linewidth=1.2, alpha=0.4, zorder=1))
    ax.text(ax_x+0.4, prv_y+8.55, 'Private subnet', ha='left', va='top',
            fontsize=7, color='#1A237E', fontweight='bold', zorder=2)

    # EKS node
    ax.add_patch(FancyBboxPatch((ax_x+0.35, prv_y+0.25), AZ_W-0.7, 7.9,
        boxstyle="round,pad=0,rounding_size=0.15",
        facecolor='#DCEDC8', edgecolor='#558B2F', linewidth=1.3, alpha=0.45, zorder=1))
    ax.text(ax_x+0.55, prv_y+7.95, 'EKS Node  t3.medium', ha='left', va='top',
            fontsize=7, color='#33691E', fontweight='bold', zorder=2)

# EKS cluster outline
ax.add_patch(FancyBboxPatch((0.65, 1.05), 24.7, 8.45,
    boxstyle="round,pad=0,rounding_size=0.3",
    facecolor='none', edgecolor='#33691E', linewidth=2.8, linestyle='--', zorder=2))
ax.text(1.1, 9.32, 'EKS Cluster  plane-app-eks-prod  (Kubernetes 1.32)',
        ha='left', va='top', fontsize=10, color='#33691E', fontweight='bold', zorder=4,
        bbox=dict(facecolor='white', edgecolor='none', alpha=0.85, pad=2))

# ═══════════════════════════════════════════════════════════════════════════════
# NAMESPACES
# ═══════════════════════════════════════════════════════════════════════════════

# ingress-nginx top band
frame(ax, 0.8, 8.0, 24.6, 1.0, '#00838F', 'ingress-nginx', fs=7.5, lw=1.5)
box(ax, 1.0,  8.12, 5.0, 0.72, '#00838F', 'NGINX Ingress Controller',                        fs=8.2)
box(ax, 6.3,  8.12, 6.0, 0.72, '#006064', '/  →  frontend  |  /api  →  backend  (TLS :443)', fs=7.8)
box(ax, 12.6, 8.12, 5.0, 0.72, '#004D40', 'TLS cert via cert-manager + Let\'s Encrypt',      fs=7.8)
box(ax, 17.9, 8.12, 7.1, 0.72, '#00695C', 'ExternalDNS: Ingress annotation → Route53 A rec', fs=7.8)

# taskboard
frame(ax, 0.8, 2.4, 7.8, 5.45, '#1976D2', 'namespace: taskboard', fs=7.5, lw=1.5)
box(ax, 1.0, 7.2,  7.4, 0.65, '#1976D2', 'Frontend  (React/Vite + nginx)  :80',                         fs=7.8)
box(ax, 1.0, 6.4,  7.4, 0.65, '#1565C0', 'Backend  (Node.js + Express)  :8000  GET/POST /api/tasks',    fs=7.6)
box(ax, 1.0, 5.6,  7.4, 0.65, '#0D47A1', 'PostgreSQL 15  —  PVC gp2 5Gi  (tasks table, auto-migrated)', fs=7.6)
box(ax, 1.0, 4.8,  7.4, 0.65, '#283593', 'Redis 7  —  cache GET /api/tasks 60 s  (invalidated on write)',fs=7.6)
box(ax, 1.0, 4.0,  7.4, 0.65, '#1A237E', 'db-migrate Job  (runs once on deploy, then Completed)',        fs=7.6)
box(ax, 1.0, 2.55, 7.4, 1.2,  '#3F51B5',
    'Images:\n207137402976.dkr.ecr.eu-west-2.amazonaws.com\n/plane-app-eks/plane-{frontend,backend}:$SHA',
    fs=7.2)

# add-ons / argocd
frame(ax, 8.85, 2.4, 7.8, 5.45, '#7B1FA2', 'namespace: argocd · cert-manager · external-dns', fs=7.5, lw=1.5)
box(ax, 9.05, 7.2,  7.4, 0.65, '#7B1FA2', 'ArgoCD  —  GitOps app-of-apps (auto-sync + self-heal)',  fs=7.8)
box(ax, 9.05, 6.4,  7.4, 0.65, '#6A1B9A', 'cert-manager  —  ClusterIssuer: DNS-01 via Route53 (IRSA)', fs=7.6)
box(ax, 9.05, 5.6,  7.4, 0.65, '#4A148C', 'ExternalDNS  —  kubernetes-sigs chart  (IRSA: Route53)',  fs=7.6)
box(ax, 9.05, 4.8,  7.4, 0.65, '#880E4F', 'EBS CSI Driver  —  StorageClass gp2  →  EBS volumes',   fs=7.6)
box(ax, 9.05, 4.0,  7.4, 0.65, '#AD1457', 'NGINX Ingress Controller  (Helm release via ArgoCD)',    fs=7.6)
box(ax, 9.05, 2.55, 7.4, 1.2,  '#C62828',
    'IRSA trust:\ncert-manager-role  /  external-dns-role\nsub: system:serviceaccount:<ns>:<sa>', fs=7.2)

# monitoring
frame(ax, 17.15, 2.4, 8.15, 5.45, '#E65100', 'namespace: monitoring  (kube-prometheus-stack)', fs=7.5, lw=1.5)
box(ax, 17.35, 7.2,  7.75, 0.65, '#E65100', 'Prometheus  —  scrapes all pods  |  PVC gp2 5Gi',          fs=7.8)
box(ax, 17.35, 6.4,  7.75, 0.65, '#BF360C', 'Grafana  —  CPU/mem, pods, nodes, Ingress dashboards',     fs=7.6)
box(ax, 17.35, 5.6,  7.75, 0.65, '#8D6E63', 'kube-state-metrics  —  Deployment / Pod / Node states',    fs=7.6)
box(ax, 17.35, 4.8,  7.75, 0.65, '#4E342E', 'node-exporter  (DaemonSet)  —  host-level metrics',        fs=7.6)
box(ax, 17.35, 4.0,  7.75, 0.65, '#6D4C41', 'alertmanager  —  alert routing rules',                     fs=7.6)
box(ax, 17.35, 2.55, 7.75, 1.2,  '#795548',
    'Grafana Ingress:\nhttps://grafana.eks.labs.virtualscale.dev\n(TLS cert via cert-manager)', fs=7.2)

# kube-system
frame(ax, 0.8, 1.12, 24.6, 1.1, '#546E7A', 'kube-system', fs=7.5, lw=1.5)
for i, (p, c) in enumerate([
    ('CoreDNS', '#546E7A'), ('kube-proxy', '#546E7A'),
    ('aws-node (VPC CNI)', '#607D8B'), ('aws-ebs-csi-driver', '#607D8B'),
    ('cluster-autoscaler', '#78909C'),
]):
    box(ax, 1.0+i*4.88, 1.25, 4.6, 0.76, c, p, fs=8)

# ═══════════════════════════════════════════════════════════════════════════════
# CONNECTORS — all dotted, orthogonal, labels in white boxes
#
# Vertical routing lanes (x):
#   2.0  — main traffic: User ↔ NLB
#   3.4  — NGINX → Frontend
#   5.0  — NGINX → Backend / Backend internals
#   6.8  — Route53 → NLB elbow exit
#   9.8  — GitHub → ECR push
#   11.0 — ECR → pods imagePull
#   13.0 — GitHub → ArgoCD
#   14.5 — cert-manager / ExternalDNS → Route53
#   21.0 — Prometheus scrape return
#
# Horizontal routing levels in gap (y 11.7–12.2):
#   11.7 — Route53 → NLB
#   11.2 — ECR imagePull return
#   10.7 — cert-manager/ExternalDNS → Route53
#   10.2 — cert-manager ↔ Let's Encrypt
# ═══════════════════════════════════════════════════════════════════════════════

C_TR  = '#0D47A1'   # traffic
C_DNS = '#E65100'   # DNS / Route53
C_CI  = '#1B5E20'   # CI/CD
C_TLS = '#4A148C'   # TLS / cert-manager
C_INT = '#00838F'   # internal routing
C_MON = '#BF360C'   # monitoring

# ── 1. User → Cloudflare (vertical down x=2.0) ───────────────────────────────
connector(ax, [(2.25, 15.8), (2.25, 15.58)], C_TR, lw=1.6)
lbl(ax, 2.75, 15.7, 'HTTPS', C_TR, ha='left')

# ── 2. Cloudflare → Route53 (horizontal right at y=15.19) ────────────────────
connector(ax, [(3.95, 15.19), (4.65, 15.19)], C_DNS, lw=1.5)
lbl(ax, 4.3, 15.35, 'NS delegation\n(labs.virtualscale.dev)', C_DNS)

# ── 3. Route53 → NLB
#   Route53 bottom (x=6.25, y=15.5) → down to y=11.7 → left to x=2.0 → down to NLB top y=11.25
connector(ax,
    [(6.25, 15.5), (6.25, 11.7), (2.0, 11.7), (2.0, 11.25)],
    C_DNS, lw=1.5)
lbl(ax, 4.1, 11.83, 'A record → NLB (eu-west-2a)', C_DNS)

# ── 4. NLB → NGINX Ingress (x=2.0, y=9.75 → y=9.0) ─────────────────────────
connector(ax, [(2.0, 9.75), (2.0, 9.0)], C_INT, lw=1.6)
lbl(ax, 2.5, 9.38, ':443 TLS', C_INT, ha='left')

# ── 5. NGINX → Frontend (x=3.4) ──────────────────────────────────────────────
connector(ax, [(3.4, 8.0), (3.4, 7.85)], C_INT, lw=1.4)
lbl(ax, 3.9, 7.93, 'GET /', C_INT, ha='left')

# ── 6. NGINX → Backend (x=5.0) ───────────────────────────────────────────────
connector(ax, [(5.0, 8.0), (5.0, 7.05)], C_INT, lw=1.4)
lbl(ax, 5.5, 7.53, '/api', C_INT, ha='left')

# ── 7. Backend → PostgreSQL ───────────────────────────────────────────────────
connector(ax, [(4.2, 6.4), (4.2, 6.25)], C_INT, lw=1.3)
lbl(ax, 4.7, 6.33, 'SQL', C_INT, ha='left')

# ── 8. Backend → Redis ────────────────────────────────────────────────────────
connector(ax, [(5.8, 6.4), (5.8, 5.45)], C_INT, lw=1.3)
lbl(ax, 6.3, 5.93, 'cache', C_INT, ha='left')

# ── 9. GitHub → ECR (docker push)
#   GitHub right (x=3.95, y=14.19) → right to x=9.8 at y=14.19 → up to ECR bottom y=15.5
connector(ax,
    [(3.95, 14.19), (9.8, 14.19), (9.8, 15.5)],
    C_CI, lw=1.5)
lbl(ax, 7.0, 14.33, 'docker push  (CI/CD pipeline)', C_CI)

# ── 10. ECR → pods imagePull
#   ECR bottom (x=9.75, y=15.5) → down to y=11.2 → left to x=4.5 → down to Frontend y=7.85
connector(ax,
    [(9.75, 15.5), (9.75, 11.2), (4.5, 11.2), (4.5, 7.85)],
    C_DNS, lw=1.3)
lbl(ax, 7.1, 11.33, 'imagePull from ECR', C_DNS)

# ── 11. GitHub → ArgoCD sync
#   GitHub right (x=3.95, y=13.8) → right to x=13.0 at y=13.4 → down into ArgoCD top y=9.0
connector(ax,
    [(3.95, 13.8), (13.0, 13.8), (13.0, 9.0)],
    C_CI, lw=1.3)
lbl(ax, 8.8, 13.94, 'argocd app sync  (CI/CD trigger)', C_CI)

# ── 12. cert-manager / ExternalDNS → Route53
#   x=14.5 lane: from y=6.4 (cert-manager) → up to y=10.7 → left to x=6.8 → up to Route53 y=15.5
connector(ax,
    [(14.5, 6.4), (14.5, 10.7), (6.8, 10.7), (6.8, 15.5)],
    C_TLS, lw=1.4)
lbl(ax, 10.7, 10.84, 'DNS-01 TXT + A record upsert  (IRSA)', C_TLS)

# ── 13. cert-manager ↔ Let's Encrypt
#   x=15.5 lane (slightly right of arrow 12): from y=6.4 → up to y=10.2 → left to x=2.25 → up to LE y=13.5
connector(ax,
    [(15.5, 6.72), (15.5, 10.2), (2.25, 10.2), (2.25, 12.5)],
    C_TLS, lw=1.2, bidir=True)
lbl(ax, 8.9, 10.34, "Let's Encrypt ACME  ↔  cert-manager", C_TLS)

# ── 14. Prometheus scrapes cluster
#   x=21.0: from monitoring bottom y=2.4 → down to y=1.8 → left across to x=1.5
connector(ax,
    [(21.0, 2.4), (21.0, 1.8), (1.5, 1.8)],
    C_MON, lw=1.3)
lbl(ax, 11.5, 1.95, 'Prometheus scrapes metrics  across all namespaces', C_MON)

# ═══════════════════════════════════════════════════════════════════════════════
# LEGEND
# ═══════════════════════════════════════════════════════════════════════════════
legend = [
    ('#0288D1', 'Public subnet / NLB'),
    ('#3949AB', 'Private subnet'),
    ('#33691E', 'EKS Cluster'),
    ('#1976D2', 'taskboard'),
    ('#7B1FA2', 'add-ons / argocd'),
    ('#E65100', 'monitoring'),
    ('#546E7A', 'kube-system'),
    ('#00838F', 'ingress-nginx'),
    ('#FF6F00', 'AWS global'),
]
for i, (c, txt) in enumerate(legend):
    lx = 0.9 + i * 2.8
    ax.add_patch(FancyBboxPatch((lx, 0.05), 0.26, 0.22,
        boxstyle="square,pad=0", facecolor=c, edgecolor='white',
        linewidth=0.8, zorder=7))
    ax.text(lx+0.35, 0.16, txt, ha='left', va='center',
            fontsize=6.5, color='#263238', zorder=8)

plt.tight_layout(pad=0.2)
plt.savefig('docs/architecture.png', dpi=150, bbox_inches='tight',
            facecolor=fig.get_facecolor())
print("Saved: docs/architecture.png")
