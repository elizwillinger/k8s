# Lab Progress

## Step 2A: Dockerfile & Image

### What was done
- Created `Dockerfile` for the e-commerce web application
- Base image: `php:8.4-apache`
- Installed `mysqli` PHP extension via `docker-php-ext-install`
- Set default database connection env vars (`DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`) pointing to `mysql-service`
- Copied application source to `/var/www/html/`
- Exposed port 80


### Build & Push
```powershell
docker buildx build -t ezwill/labrepo:v1 .
docker push ezwill/labrepo:v1
```

### Notes
- `index.php` already reads DB credentials from environment variables — no code changes needed
- `mysql-service` is a Kubernetes service name; won't resolve in standalone Docker (expected for K8s deployment)

