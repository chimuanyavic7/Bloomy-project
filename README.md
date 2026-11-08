# Bloomy Project

A containerized, multi-service application deployed to AWS using a fully automated **CI/CD pipeline**. Infrastructure is provisioned with **Terraform**, servers are configured with **Ansible**, and applications are built, versioned, and released with **GitHub Actions** and **Docker**.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Repository Structure](#repository-structure)
- [Services](#services)
- [CI/CD Workflows](#cicd-workflows)
- [Prerequisites](#prerequisites)
- [Configuration: Secrets and Variables](#configuration-secrets-and-variables)
- [Getting Started](#getting-started)
- [Local Development](#local-development)
- [Security Practices](#security-practices)
- [Troubleshooting](#troubleshooting)
- [Glossary](#glossary)

---

## Overview

Bloomy consists of two containerized services (a **Java** backend and a **portfolio** web application) running on a single **AWS EC2** instance. The project demonstrates a complete **DevOps** workflow, following the principle of **Infrastructure as Code (IaC)**:

| Stage | Tool | Purpose |
|---|---|---|
| Provision | Terraform | Create and destroy AWS infrastructure |
| Configure | Ansible | Install Docker, AWS CLI, and clone the repository on the server |
| Build | Docker + GitHub Actions | Build and publish versioned container images |
| Deploy | GitHub Actions + SSH + Docker Compose | Release the new version to the server |

---

## Architecture

```
                 ┌──────────────────────────┐
                 │     GitHub Repository    │
                 └────────────┬─────────────┘
                              │  push / pull request / manual trigger
                              ▼
                 ┌──────────────────────────┐
                 │      GitHub Actions      │
                 │  Version → Build → Deploy│
                 └──────┬───────────┬───────┘
                        │           │
          push images   │           │  SSH deploy
                        ▼           ▼
                 ┌────────────┐  ┌──────────────────────────┐
                 │ Docker Hub │  │    AWS EC2 (Ubuntu)      │
                 └────────────┘  │  ┌────────────────────┐  │
                        ▲        │  │   Docker Compose   │  │
                        └────────┼──│   • bloomy-java    │  │
                      pull       │  │   • bloomy-portfolio│ │
                                 │  └────────────────────┘  │
                                 └──────────────────────────┘
                                           ▲
                        Terraform (provision) + Ansible (configure)
```

---

## Tech Stack

- **Cloud Provider:** AWS (EC2, region `eu-central-1`)
- **Infrastructure as Code:** Terraform
- **Configuration Management:** Ansible
- **Containerization:** Docker, Docker Compose, Docker Buildx
- **Container Registry:** Docker Hub
- **CI/CD:** GitHub Actions
- **Application Services:** Java, Portfolio web app
- **Operating System:** Ubuntu

---

## Repository Structure

```
Bloomy-project/
├── .github/
│   └── workflows/
│       ├── pipeline.yml          # CI/CD: version, build, push, deploy
│       ├── ansible.yml           # Server configuration
│       └── terraform.yml         # Infrastructure provisioning
├── ansible/
│   └── playbook.yml              # Server setup tasks
├── terraform/
│   └── dev.tfvars                # Environment variables for Terraform
├── java/                         # Java service (with Dockerfile)
├── myportfolio/                  # Portfolio service (with Dockerfile)
├── docker-compose.yml            # Runtime definition of all services
└── README.md
```

---

## Services

| Service | Container Name | Image | Host Port | Container Port |
|---|---|---|---|---|
| Java backend | `bloomy-java` | `<DOCKERHUB_USERNAME>/bloomy-java:<IMAGE_TAG>` | 8081 | 8081 |
| Portfolio | `bloomy-myportfolio` | `<DOCKERHUB_USERNAME>/bloomy-myportfolio:<IMAGE_TAG>` | 80 | 8080 |

Both services share a private Docker **bridge network** (`bloomy-network`) and use the `unless-stopped` **restart policy**, so they recover automatically after a crash or server reboot.

---

## CI/CD Workflows

### 1. Pipeline (Build and Deploy)

**File:** `pipeline.yml`

**Triggers**
- Push to `main` when files in `java/` or `myportfolio/` change
- Pull requests (any branch) when files in `java/` or `myportfolio/` change
- Manual run (`workflow_dispatch`)

**Jobs**

| Job | Description |
|---|---|
| **Generate Image Version** | Creates an immutable **image tag** from the first 7 characters of the Git commit SHA, so every build is traceable to an exact commit. |
| **Docker Build** | Builds the `bloomy-java` and `bloomy-myportfolio` images, pushes them to Docker Hub, and generates **provenance** and **SBOM** attestations. Uses **GitHub Actions cache** to speed up builds. |
| **Deploy to EC2** | Runs only on `main` (push or manual run). Connects over SSH, checks out the exact commit, logs in to Docker Hub, pulls the new images, and restarts the services with Docker Compose. |

> Pull requests run the build job only. Deployment is restricted to the `main` branch.

### 2. Terraform Infrastructure

**File:** `terraform.yml` | **Trigger:** Manual only

Provisions or destroys the AWS infrastructure.

1. Initializes and validates the Terraform configuration
2. Creates an execution plan (`terraform plan`) and displays it in the logs
3. Applies the plan (`apply`) or tears everything down (`destroy`)
4. On `apply`, saves the server's public IP to the `EC2_HOST` repository variable and verifies it matches
5. On `destroy`, removes the `EC2_HOST` variable

A **concurrency lock** ensures only one Terraform operation runs at a time, protecting the Terraform **state** from corruption.

### 3. Ansible Configuration

**File:** `ansible.yml` | **Trigger:** Manual only

Configures the EC2 server after it has been provisioned.

1. Installs Ansible and prepares the SSH key
2. Registers the server in `known_hosts`
3. Generates a dynamic **inventory** file
4. Tests connectivity with `ansible ping`
5. Runs `playbook.yml`, which:
   - Updates the system and installs `git`, `curl`, `unzip`, and certificates
   - Installs **AWS CLI v2**
   - Installs **Docker Engine**, **Docker Compose plugin**, and **Buildx**
   - Adds the `ubuntu` user to the `docker` group
   - Clones this repository to `/home/ubuntu/Bloomy-project`
6. Deletes the temporary SSH key (always, even if a step fails)

---

## Prerequisites

- An AWS account with permission to manage EC2 resources
- A Docker Hub account and an **access token**
- A GitHub **Personal Access Token (PAT)** with permission to manage repository variables
- An SSH key pair for server access
- *(For local use)* Docker, Docker Compose, Terraform, and Ansible installed

---

## Configuration: Secrets and Variables

Add the following under **Settings → Secrets and variables → Actions** in your GitHub repository.

### Secrets

| Name | Description |
|---|---|
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
| `EC2_USER` | SSH username for the server (for example, `ubuntu`) |
| `EC2_SSH_KEY` | Private SSH key used to connect to the server |
| `AWS_ACCESS_KEY_ID` | AWS access key for Terraform |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key for Terraform |
| `GH_PAT` | GitHub PAT used by the Terraform workflow to update repository variables |

### Variables

| Name | Description |
|---|---|
| `EC2_HOST` | Public IP of the EC2 server. **Set automatically** by the Terraform workflow. |

---

## Getting Started

Run the workflows in this order for a first-time setup.

**Step 1: Provision infrastructure**
Go to **Actions → Terraform Infrastructure → Run workflow** and select `apply`.
This creates the EC2 instance and stores its IP in `EC2_HOST`.

**Step 2: Configure the server**
Go to **Actions → Ansible Configuration → Run workflow**.
This installs Docker and clones the repository onto the server.

**Step 3: Deploy the application**
Push a change to `main` under `java/` or `myportfolio/`, or run **Pipeline** manually.
The workflow builds, publishes, and deploys the new version.

**Step 4: Verify**
- Portfolio: `http://<EC2_HOST>`
- Java service: `http://<EC2_HOST>:8081`

> Ensure the EC2 **security group** allows inbound traffic on ports `22` (SSH), `80` (HTTP), and `8081`.

### Tearing Down

Run **Terraform Infrastructure** with the `destroy` action to remove all AWS resources and clear `EC2_HOST`.

---

## Local Development

Run the services locally with Docker Compose:

```bash
# Set required environment variables
export DOCKERHUB_USERNAME=<your-username>
export IMAGE_TAG=<image-tag>

# Validate the configuration
docker compose config -q

# Pull images and start services in the background
docker compose pull
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down
```

To build images locally instead of pulling them:

```bash
docker build -t bloomy-java ./java
docker build -t bloomy-myportfolio ./myportfolio
```

---

## Security Practices

- **Least privilege:** Workflow permissions default to `contents: read`.
- **Secrets management:** Credentials are stored as encrypted GitHub Secrets and are never committed to the repository.
- **Supply chain security:** Images are built with **provenance** and **SBOM** (Software Bill of Materials) attestations.
- **Immutable versioning:** Images are tagged with the commit SHA, not `latest`, enabling reliable rollbacks.
- **Safe credential handling:** Docker Hub login uses `--password-stdin`, and the session is closed with `docker logout` after deployment.
- **Temporary SSH keys:** The key is written with `600` permissions and removed after every Ansible run.
- **Host verification:** `ssh-keyscan` populates `known_hosts` before connecting.
- **State protection:** Concurrency control prevents parallel Terraform runs.
- **Plan review:** Terraform plans are generated and printed before they are applied.

---

## Troubleshooting

| Problem | Likely Cause | Solution |
|---|---|---|
| `EC2_HOST is empty` | Terraform has not been applied, or it was destroyed | Run the Terraform workflow with `apply` |
| SSH connection fails | Wrong key, user, or closed port 22 | Verify `EC2_SSH_KEY`, `EC2_USER`, and the security group |
| `dev.tfvars was not found` | Missing file | Add `terraform/dev.tfvars` to the repository |
| Deploy fails at `git checkout` | Server repository was not cloned | Run the Ansible workflow first |
| `docker compose pull` fails | Image tag does not exist | Confirm the build job succeeded and the Docker Hub credentials are correct |
| Docker permission denied | User not yet in `docker` group | Reconnect the SSH session after running Ansible |

### Rolling Back

Because every image is tagged with a commit SHA, you can redeploy a previous version by re-running the **Pipeline** workflow on an earlier commit, or by running this on the server:

```bash
export DOCKERHUB_USERNAME=<your-username>
export IMAGE_TAG=<previous-7-char-sha>
docker compose up -d
```

---

## Glossary

| Term | Meaning |
|---|---|
| **CI/CD** | Continuous Integration / Continuous Delivery: automating build, test, and release. |
| **Infrastructure as Code (IaC)** | Managing servers and cloud resources through code instead of manual setup. |
| **Terraform** | A tool that creates cloud infrastructure from declarative configuration files. |
| **Ansible** | An automation tool that configures servers using playbooks. |
| **Playbook** | An Ansible file that lists the tasks to run on a server. |
| **Inventory** | An Ansible file that lists the servers to manage. |
| **Docker Image** | A packaged, read-only template containing an application and its dependencies. |
| **Container** | A running instance of a Docker image. |
| **Docker Compose** | A tool for defining and running multi-container applications. |
| **Image Tag** | A label identifying a specific version of an image. |
| **Provenance** | A verifiable record of how and where an image was built. |
| **SBOM** | Software Bill of Materials: a list of all components inside an image. |
| **EC2** | Amazon's virtual server service. |
| **Security Group** | A virtual firewall controlling traffic to an EC2 instance. |
| **Terraform State** | A record of the infrastructure Terraform currently manages. |
| **Concurrency Lock** | A rule preventing multiple workflow runs from overlapping. |

---

```bash
sudo docker run --rm \
  -v "$(pwd)/certbot/conf:/etc/letsencrypt" \
  -v "$(pwd)/certbot/www:/var/www/certbot" \
  certbot/certbot certonly \
  --webroot \
  -w /var/www/certbot \
  -d vikkychi.site \
  -d www.vikkychi.site \
  -d app.vikkychi.site \
  --email (add your email address) \
  --agree-tos \
  --no-eff-email
```