# IBM Guestbook — Containers, Kubernetes & OpenShift

This is a fork of the [IBM Developer Skills Network Guestbook](https://github.com/ibm-developer-skills-network/guestbook).

Completed for the course exercise:
- Dockerfiles with `COPY` and `EXPOSE 3000` for v1 and v2.
- HTML with `Guestbook - v1` and `Guestbook - v2` in both the `title` and `h1`.
- Kubernetes Deployment templates with different image tags and CPU requests/limits.
- A script for generating real evidence **inside your IBM Cloud / Kubernetes lab**.
- GitHub Actions checks for Docker builds and a local HTTP smoke test.

**[Read the full final project guide](SUBMISSION_GUIDE.md)** before executing the lab. GitHub code by itself does not verify image pushes, HPA scaling or rollback in IBM Cloud.
