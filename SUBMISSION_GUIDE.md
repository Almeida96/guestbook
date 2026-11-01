# IBM Skills Network — Guestbook Final Project

This fork contains the code for Guestbook v1/v2, two Dockerfiles, two Kubernetes Deployment templates, and a helper script that saves **real** terminal output into an untracked `evidence/` directory.

**GitHub alone is not the IBM Cloud lab.** The assignments asking for IBM Container Registry output, HPA replicas, image push, rollout and rollback require an authenticated IBM Cloud account and Kubernetes cluster. These outputs must be produced by commands in your actual lab, not invented.

## Setup in the IBM Skills Network lab terminal

1. Confirm that `docker`, `ibmcloud`, and `kubectl` are installed and authenticated to the course lab.
2. Clone your fork:
   
   ```bash
   git clone https://github.com/Almeida96/guestbook.git
   cd guestbook
   ```

3. Get the **real** IBM Container Registry namespace and make sure your cluster is reachable:

   ```bash
   ibmcloud cr namespace-list
   kubectl get nodes
   ```

4. Set your real namespace (replace the placeholder, without angle brackets):

   ```bash
   export MY_NAMESPACE="YOUR_ACTUAL_IBM_NAMESPACE"
   ```

5. If Docker is not logged into the IBM Container Registry, follow the lab's instructions for `ibmcloud cr login`. Do not commit credentials, CLI tokens or kubeconfig files.

## Run the actual exercise

Run these from the fork root, in order:

```bash
# Build/push v1 and deploy; capture real "ibmcloud cr images"
bash scripts/lab.sh v1

# Create HPA and record initial status, then generate real workload
bash scripts/lab.sh autoscale

# Observe kubectl get hpa; only proceed when replicas have actually grown
bash scripts/lab.sh hpa-after

# Stop the load generator to avoid unnecessary cluster resource usage
bash scripts/lab.sh cleanup

# Build/push v2 and apply a different image and CPU resource allocation
bash scripts/lab.sh v2

# Capture actual rollout details and execute rollback
bash scripts/lab.sh rollback
```

The script renders each deployment template with your `MY_NAMESPACE` into `evidence/deployment-v1.yml` and `evidence/deployment-v2.yml` before applying it. The repository's source manifests have `__NAMESPACE__` placeholders and should not be applied directly.

If HPA metrics are unavailable, inspect `kubectl top pods` and `kubectl describe hpa guestbook`. The helper explicitly warns when it has not observed 2+ replicas; a command output with 1 replica does not satisfy the autoscaling evidence requirement.

## Where to find the 10 answers

| Question | Required submission | Actual file |
| --- | --- | --- |
| 1 | Completed Dockerfile with COPY and EXPOSE | [v1 Dockerfile](v1/guestbook/Dockerfile) |
| 2 | IBM registry image listing with tag v1 | `evidence/crimages` |
| 3 | HTML with Guestbook - v1 in title and h1 | [v1 HTML](v1/guestbook/public/index.html) |
| 4 | Initial HPA status with all columns | `evidence/hpa` |
| 5 | HPA status showing a real increase in replicas | `evidence/hpa2` |
| 6 | Real output of pushing the v2 image | `evidence/upguestbook` |
| 7 | Real `kubectl apply` output for v2 | `evidence/deployment` |
| 8 | HTML with Guestbook - v2 in title and h1 | [v2 HTML](v2/guestbook/public/index.html) |
| 9 | Rollout revision with CPU values | `evidence/rev` |
| 10 | Two ReplicaSets after rollback | `evidence/rs` |

To confirm v2 is live before rollback, run `kubectl port-forward deployment/guestbook 3000:3000` and visit `http://localhost:3000`, or use your lab's forwarded port URL.

The evidence directory is gitignored and is created locally **only when you actually execute the commands**. Do not submit fabricated output or claim that GitHub Actions verified the IBM Cloud lab. GitHub Actions tests only the Docker build and local HTTP response.

Review and understand the work and follow the Coursera honor code, including any restrictions on submitting AI-assisted code as your own.
