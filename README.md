# OpenNexcore Platform

**OpenNexcore** is an open-source multi-tenant platform for building enterprise SaaS applications.  
It provides tenant management, role-based access control, policy-driven API security, and a modular Angular frontend.

---

## Quick Deploy with install.sh

Deploy a full running instance in minutes — you only need **Docker** and **Docker Compose**.

### Prerequisites

- Ubuntu 20.04+ (or any Linux with Docker)
- Docker Engine + Docker Compose plugin
- A Docker Hub account with the published images

> **First time on a fresh server?**  
> Install Docker automatically:
> ```bash
> curl -fsSL https://get.docker.com | bash
> sudo usermod -aG docker $USER && newgrp docker
> ```

---

### Step 1 — Download and run the installer

```bash
curl -fsSL https://raw.githubusercontent.com/crodrigr/nexcore/master/nexcore-infra/deploy/install.sh | bash
```

This will:
- Create `~/nexcore/` with all necessary files
- Download `Makefile`, `docker-compose.hub.yml`, and SQL scripts
- Create a `.env` file from the template

---

### Step 2 — Configure the environment

```bash
nano ~/nexcore/.env
```

At minimum, set these values:

```env
# Do not change — points to the published images
DOCKER_HUB_USER=crodrigr

# Database password
DB_PASSWORD=your-secure-password

# JWT secret — generate with: openssl rand -hex 32
JWT_SECRET=your-256-bit-secret

# Public URL of your server (IP or domain)
CORS_ALLOWED_ORIGINS=http://<YOUR-IP>:4200
APP_FRONTEND_URL=http://<YOUR-IP>:4200
FRONTEND_URL=http://<YOUR-IP>:4200

# Email (Gmail app password — not your account password)
GMAIL_USER=your-email@gmail.com
GMAIL_PASS=xxxx xxxx xxxx xxxx
```

---

### Step 3 — Initialize the database

```bash
cd ~/nexcore/nexcore-infra/deploy
make install
```

This starts PostgreSQL, Redis and Postfix, then loads the schema and seed data.  
**Run only once.** If the database is already initialized, it will show an error — use `make db-reset` to start over (⚠ deletes all data).

---

### Step 4 — Start all services

```bash
make up-hub
```

This pulls the latest Docker images from Docker Hub and starts all 6 containers.

---

### Access the application

| Service        | URL                        |
|----------------|----------------------------|
| Frontend       | `http://<YOUR-IP>:4200`    |
| Core API       | `http://<YOUR-IP>:8080`    |
| Auth API       | `http://<YOUR-IP>:8081`    |

**Default credentials:**

| Tenant   | User          | Password       | Role         |
|----------|---------------|----------------|--------------|
| system   | `super.admin` | `NexCore@2026!`| SUPER_ADMIN  |
| demo     | `test.admin`  | `NexCore@2026!`| TENANT_ADMIN |
| demo     | `test.editor` | `NexCore@2026!`| EDITOR       |

---

### Useful commands

```bash
make up-hub        # Start all services
make down-hub      # Stop all services
make restart-hub   # Restart app containers (without touching DB)
make logs          # Stream logs from all containers
make status        # Show container status
make db-reset      # ⚠ Recreate DB from scratch (deletes all data)
```

---

### Update to a new version

```bash
make down-hub
make up-hub        # pulls latest images and restarts
```

No need to re-run `make install` on updates — only on first install.

---

## Architecture

```
nexcore-frontend  (Angular 20 + nginx)   :4200
nexcore-core      (Spring Boot 3)        :8080
nexcore-auth      (Spring Boot 3)        :8081
postgres          (PostgreSQL 15)        :5432
redis             (Redis 7)             :6379
postfix           (email relay)          :1587
```

---

## License

Copyright 2026 **Camilo Rodriguez** · [crodrigr@gmail.com](mailto:crodrigr@gmail.com)  
GitHub: [github.com/crodrigr/nexcore](https://github.com/crodrigr/nexcore)

OpenNexcore is released under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).  
Free to use, modify and distribute — including commercial use.
