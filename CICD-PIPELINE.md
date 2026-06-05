# End-to-End CI/CD Pipeline — Rufous PaaS (GKE)

Production runbook for the `rufous-web` application pipeline.
**Flow:** commit → build → unit/integration tests → SAST/quality gate → dependency scan → build image (once) → image scan → push to Artifact Registry → deploy `dev` → deploy `test` (smoke) → **manual approval** → deploy `prod` → verify rollout / auto-rollback.

Auth is **keyless** via Workload Identity Federation (OIDC). No service-account JSON keys are stored anywhere.

---

## 1. Architecture & Real-Time Flow

```
 Developer                 GitHub Actions                       GCP / GKE
 ─────────                 ──────────────                       ──────────
   |                            |                                   |
   |── git push main ──────────►|                                   |
   |                            |── build-test (mvn verify) ────────|
   |                            |     ├─ SonarQube quality gate     |
   |                            |     └─ Snyk deps scan             |
   |                            |                                   |
   |                            |── build-image ───────────────────►| Artifact Registry
   |                            |     ├─ docker build/push          |   us-central1-docker.pkg.dev
   |                            |     └─ Trivy image scan           |
   |                            |                                   |
   |                            |── deploy-dev ────────────────────►| GKE: ns=dev
   |                            |     └─ kubectl rollout status     |
   |                            |                                   |
   |                            |── deploy-test ───────────────────►| GKE: ns=test
   |                            |     ├─ rollout status             |
   |                            |     └─ smoke tests                |
   |                            |                                   |
   |                            |── [GATE] manual approval ─────────|   (GitHub Environment reviewers)
   |                            |                                   |
   |                            |── deploy-prod ───────────────────►| GKE: ns=prod
   |                            |     ├─ rollout status (300s)      |
   |                            |     └─ auto-rollback on failure   |
   |                            |                                   |
```

**Key invariant:** the image built in stage 2 is the *exact* artifact that lands in prod. Tag = `github.sha`. No rebuilds between environments.

---

## 2. Prerequisites

### GCP resources (provisioned by Terraform in this repo)
- Project: `rufous-ai`
- GKE cluster: `rufous-ai-paas` in `us-central1`
- Artifact Registry repo: `paas-rufous-ai` in `us-central1`
- Namespaces in cluster: `dev`, `test`, `prod`
- A `Deployment` named `rufous-web` already created in each namespace (the pipeline does `set image`, not first-time apply)

### GitHub Repository configuration

**Repository Variables** (Settings → Secrets and variables → Actions → Variables):
| Name | Example value |
|---|---|
| `GCP_WIF_PROVIDER` | `projects/123456789/locations/global/workloadIdentityPools/github/providers/gh` |
| `GCP_DEPLOY_SA` | `gh-deployer@rufous-ai.iam.gserviceaccount.com` |
| `SONAR_HOST_URL` | `https://sonar.example.com` |

**Repository Secrets:**
| Name | Purpose |
|---|---|
| `SONAR_TOKEN` | SonarQube auth |
| `SNYK_TOKEN` | Snyk auth |

**GitHub Environments** (Settings → Environments):
- `dev` — no protection rules
- `test` — no protection rules
- `production` — **required reviewers** (1+), optional wait timer, deployment branch rule `main` only

---

## 3. One-time Setup — Workload Identity Federation (keyless auth)

Run these once as a project owner. They establish the trust between GitHub OIDC and the deploy service account.

```bash
PROJECT_ID=rufous-ai
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
POOL=github
PROVIDER=gh
REPO=ORG/REPO          # <-- your GitHub org/repo
SA=gh-deployer@$PROJECT_ID.iam.gserviceaccount.com

# 1. Create the deploy service account
gcloud iam service-accounts create gh-deployer \
  --project=$PROJECT_ID \
  --display-name="GitHub Actions deployer"

# 2. Grant the SA only what it needs
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA" \
  --role="roles/artifactregistry.writer"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA" \
  --role="roles/container.developer"     # kubectl access; tighten to namespace RBAC if possible

# 3. Create the WIF pool + GitHub OIDC provider
gcloud iam workload-identity-pools create $POOL \
  --project=$PROJECT_ID --location=global \
  --display-name="GitHub Actions pool"

gcloud iam workload-identity-pools providers create-oidc $PROVIDER \
  --project=$PROJECT_ID --location=global \
  --workload-identity-pool=$POOL \
  --display-name="GitHub OIDC" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref" \
  --attribute-condition="assertion.repository=='$REPO'" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# 4. Allow the GitHub repo to impersonate the SA
gcloud iam service-accounts add-iam-policy-binding $SA \
  --project=$PROJECT_ID \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$POOL/attribute.repository/$REPO"

# 5. Print the provider resource name -- paste into GCP_WIF_PROVIDER repo variable
echo "projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$POOL/providers/$PROVIDER"
```

---

## 4. Pipeline YAML

Path in the application repo: `.github/workflows/cicd.yml`

```yaml
name: CI/CD - Build, Scan & Deploy to GKE

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: false

permissions:
  contents: read
  id-token: write          # required for keyless OIDC to GCP

env:
  GCP_PROJECT_ID: rufous-ai
  GCP_REGION: us-central1
  GAR_REPO: paas-rufous-ai
  IMAGE_NAME: rufous-web
  GKE_CLUSTER: rufous-ai-paas
  IMAGE_URI: us-central1-docker.pkg.dev/rufous-ai/paas-rufous-ai/rufous-web:${{ github.sha }}

jobs:

  # ── 1. BUILD & TEST ──────────────────────────────────────────────────────
  build-test:
    name: Build, Test & Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
          cache: maven

      - name: Build & run tests
        run: mvn -B clean verify

      - name: SonarQube quality gate
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: ${{ vars.SONAR_HOST_URL }}
        run: >
          mvn -B sonar:sonar
          -Dsonar.host.url=$SONAR_HOST_URL
          -Dsonar.token=$SONAR_TOKEN
          -Dsonar.qualitygate.wait=true

      - name: Snyk dependency scan
        uses: snyk/actions/maven@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high

      - name: Upload build artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-jar
          path: target/*.jar
          retention-days: 1

  # ── 2. BUILD & PUSH IMAGE ────────────────────────────────────────────────
  build-image:
    name: Build & Push Image
    needs: build-test
    if: github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/download-artifact@v4
        with:
          name: app-jar
          path: target

      - name: Authenticate to GCP (keyless / WIF)
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ vars.GCP_WIF_PROVIDER }}
          service_account: ${{ vars.GCP_DEPLOY_SA }}

      - uses: google-github-actions/setup-gcloud@v2

      - name: Configure Docker for Artifact Registry
        run: gcloud auth configure-docker ${{ env.GCP_REGION }}-docker.pkg.dev --quiet

      - name: Build & push image (tagged by SHA)
        run: |
          docker build -t "$IMAGE_URI" .
          docker push "$IMAGE_URI"

      - name: Scan image with Trivy
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.IMAGE_URI }}
          severity: HIGH,CRITICAL
          exit-code: '1'

  # ── 3. DEPLOY → DEV ──────────────────────────────────────────────────────
  deploy-dev:
    name: Deploy to Dev
    needs: build-image
    runs-on: ubuntu-latest
    environment: dev
    steps:
      - uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ vars.GCP_WIF_PROVIDER }}
          service_account: ${{ vars.GCP_DEPLOY_SA }}
      - uses: google-github-actions/get-gke-credentials@v2
        with:
          cluster_name: ${{ env.GKE_CLUSTER }}
          location: ${{ env.GCP_REGION }}
      - name: Deploy & verify rollout
        run: |
          kubectl -n dev set image deployment/${{ env.IMAGE_NAME }} \
            ${{ env.IMAGE_NAME }}=${{ env.IMAGE_URI }}
          kubectl -n dev rollout status deployment/${{ env.IMAGE_NAME }} --timeout=180s

  # ── 4. DEPLOY → TEST ─────────────────────────────────────────────────────
  deploy-test:
    name: Deploy to Test
    needs: deploy-dev
    runs-on: ubuntu-latest
    environment: test
    steps:zz
      - uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ vars.GCP_WIF_PROVIDER }}
          service_account: ${{ vars.GCP_DEPLOY_SA }}
      - uses: google-github-actions/get-gke-credentials@v2
        with:
          cluster_name: ${{ env.GKE_CLUSTER }}
          location: ${{ env.GCP_REGION }}
      - name: Deploy & verify rollout
        run: |
          kubectl -n test set image deployment/${{ env.IMAGE_NAME }} \
            ${{ env.IMAGE_NAME }}=${{ env.IMAGE_URI }}
          kubectl -n test rollout status deployment/${{ env.IMAGE_NAME }} --timeout=180s
      - name: Smoke test
        run: |
          curl -fsS --retry 5 --retry-delay 5 https://test.rufous.com/healthz

  # ── 5. DEPLOY → PROD (gated) ─────────────────────────────────────────────
  deploy-prod:
    name: Deploy to Prod
    needs: deploy-test
    runs-on: ubuntu-latest
    environment: production       # required reviewers configured on this Environment
    steps:
      - uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ vars.GCP_WIF_PROVIDER }}
          service_account: ${{ vars.GCP_DEPLOY_SA }}
      - uses: google-github-actions/get-gke-credentials@v2
        with:
          cluster_name: ${{ env.GKE_CLUSTER }}
          location: ${{ env.GCP_REGION }}
      - name: Deploy & verify rollout
        run: |
          kubectl -n prod set image deployment/${{ env.IMAGE_NAME }} \
            ${{ env.IMAGE_NAME }}=${{ env.IMAGE_URI }}
          kubectl -n prod rollout status deployment/${{ env.IMAGE_NAME }} --timeout=300s
      - name: Auto-rollback on failed rollout
        if: failure()
        run: |
          echo "Rollout failed - rolling back to previous revision"
          kubectl -n prod rollout undo deployment/${{ env.IMAGE_NAME }}
```

---

## 5. Stage-by-Stage Reference

| # | Stage | Trigger | Typical duration | Gate | Failure behavior |
|---|---|---|---|---|---|
| 1 | `build-test` | every push / PR | 3–6 min | Sonar quality gate, Snyk HIGH | Job fails, no image built |
| 2 | `build-image` | push to `main` only | 2–4 min | Trivy HIGH/CRITICAL | Job fails, image pushed but downstream blocked |
| 3 | `deploy-dev` | after `build-image` | ~1 min | `kubectl rollout status` 180s | Job fails, dev pods unhealthy |
| 4 | `deploy-test` | after `deploy-dev` | 1–2 min | rollout + smoke test | Job fails, test env unhealthy |
| 5 | `deploy-prod` | manual approval | ~2 min | rollout 300s + auto-rollback | `rollout undo` to previous revision |

---

## 6. Operational Runbook

### Watching a run in real time
- GitHub UI: **Actions** tab → click the running workflow → live logs per job.
- CLI: `gh run watch` (in the app repo) — streams the active run.
- Cluster view: `kubectl -n <env> rollout status deployment/rufous-web -w`

### Manual rollback (post-deploy)
```bash
kubectl -n prod rollout history deployment/rufous-web
kubectl -n prod rollout undo deployment/rufous-web --to-revision=<N>
```

### Re-deploy a specific SHA (e.g. promote an older known-good build)
```bash
SHA=<git-sha>
IMG=us-central1-docker.pkg.dev/rufous-ai/paas-rufous-ai/rufous-web:$SHA
kubectl -n prod set image deployment/rufous-web rufous-web=$IMG
kubectl -n prod rollout status deployment/rufous-web --timeout=300s
```

### Pause / resume the pipeline
- Disable the workflow: **Actions** → workflow → ⋯ → *Disable workflow*.
- Block prod only: remove approvers from the `production` environment.

---

## 7. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `Permission 'iam.serviceAccounts.getAccessToken' denied` | WIF binding missing or wrong `attribute.repository` | Re-check the `principalSet://` member, confirm `GCP_WIF_PROVIDER` repo var |
| `denied: Permission "artifactregistry.repositories.uploadArtifacts" denied` | SA missing `artifactregistry.writer` | Add the role to `gh-deployer` SA |
| `error: deployment "rufous-web" not found` | Deployment never applied in target namespace | Apply base manifests first; pipeline only updates image |
| `rollout status` times out | Pod crashlooping, image pull error, failing probes | `kubectl describe pod` / `kubectl logs` in that namespace |
| Trivy job fails on HIGH CVE | Base image vulnerable | Bump base image in `Dockerfile`, or add a justified `.trivyignore` entry |
| Sonar gate fails | Coverage/bugs/duplications below threshold | Fix in code, or adjust quality gate in Sonar |

---

## 8. Security & Compliance Notes

- **Keyless auth (WIF):** no static GCP keys in GitHub. Rotation is automatic via short-lived OIDC tokens.
- **Image immutability:** SHA-tagged tags are never overwritten. `:latest` is not used.
- **Three independent scans:** Sonar (SAST/quality), Snyk (deps), Trivy (image). All block the pipeline on HIGH+.
- **Approval gate on prod:** GitHub Environment required reviewers; deployment branch restricted to `main`.
- **Concurrency lock:** `cancel-in-progress: false` queues runs so prod deploys serialize.
- **Least privilege:** `gh-deployer` SA only has `artifactregistry.writer` + `container.developer`. Tighten to per-namespace RBAC in-cluster for stricter setups.

---

## 9. File Location

This pipeline (`cicd.yml`) lives in the **application repository** under `.github/workflows/`.
This document lives in the **Terraform/PaaS repo** (`envs/pass/CICD-PIPELINE.md`) because the pipeline consumes infrastructure provisioned here (GKE cluster, Artifact Registry, WIF pool, namespaces).
