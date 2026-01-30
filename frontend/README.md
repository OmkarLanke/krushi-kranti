# Krushi Kranti Frontend (Production Docker)

Single Docker image serving:

- **Landing page** – `krushikranti.ltd`, `www.krushikranti.ltd` (static HTML/CSS/JS from `krushikranti-landing-page/`)
- **Admin web app** – `admin.krushikranti.ltd` (Flutter web build with production BASE_URL)
- **API proxy** – `api.krushikranti.ltd` → API Gateway (backend)

## Build

**From repository root** (parent of `frontend/`, `krushikranti_admin/`, `krushikranti-landing-page/`):

```bash
docker build -f frontend/Dockerfile -t krushi-frontend:latest .
```

Optional: override production API URL at build time:

```bash
docker build -f frontend/Dockerfile \
  --build-arg BASE_URL=https://api.krushikranti.ltd \
  -t krushi-frontend:latest .
```

## Run (production – with SSL)

Certbot must be run on the host first. Then mount certs and run:

```bash
docker run -d \
  --name krushi-frontend \
  -p 80:80 -p 443:443 \
  -v /etc/letsencrypt:/etc/letsencrypt:ro \
  --network krushi-kranti-network \
  krushi-frontend:latest
```

Ensure the container is on the **same Docker network** as the backend so `api-gateway:4004` resolves (e.g. `krushi-kranti-network` from backend `docker-compose`).

After Certbot renewal, reload Nginx:

```bash
docker exec krushi-frontend nginx -s reload
```

## Run with Docker Compose (local / Docker Desktop)

From **repository root**:

```bash
docker compose -f docker-compose.frontend.yml up --build -d
```

**First build can take 10–15+ minutes** (Flutter image pull + `flutter build web`). Then open:

- **Landing:** http://localhost:8080  
- **Admin:** http://localhost:8081  

No hosts file needed. To stop: `docker compose -f docker-compose.frontend.yml down`.

## Run (local testing – no SSL, manual)

Use HTTP-only config so the container works without mounted certs:

```bash
docker run -d \
  --name krushi-frontend \
  -p 8080:80 -p 8081:8081 \
  -v $(pwd)/frontend/nginx-http-only.conf:/etc/nginx/conf.d/default.conf:ro \
  krushi-frontend:latest
```

Then open `http://localhost:8080` (landing) and `http://localhost:8081` (admin). For API proxy to work, backend must be running and the container must be on the same network as `api-gateway`.

## Contents

| Path in image           | Source                          |
|-------------------------|----------------------------------|
| `/usr/share/nginx/html/landing` | `krushikranti-landing-page/`     |
| `/usr/share/nginx/html/admin`   | Flutter web build (`krushikranti_admin`) with `BASE_URL=https://api.krushikranti.ltd` |
| `/etc/nginx/conf.d/default.conf` | `frontend/nginx.conf` (HTTPS)     |

## Requirements

- Build context = **repository root** (so `krushikranti_admin/`, `krushikranti-landing-page/`, and `frontend/` are available).
- Production: Certbot on host; mount `/etc/letsencrypt` into the container.
- Production: Frontend and backend on same Docker network so Nginx can proxy to `api-gateway:4004`.
