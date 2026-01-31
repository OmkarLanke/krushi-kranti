# ============================================================
# Stage 1: Build Admin (Flutter web) - production BASE_URL
# ============================================================
# Use Cirrus Labs Flutter image (has Flutter SDK for web build)
FROM ghcr.io/cirruslabs/flutter:stable AS admin-builder

WORKDIR /app

# Copy admin app and get dependencies
COPY krushikranti_admin /app/krushikranti_admin
WORKDIR /app/krushikranti_admin

# Production API base URL (baked into build)
ARG BASE_URL=https://api.krushikranti.ltd
ENV BASE_URL=${BASE_URL}

RUN flutter pub get && \
    flutter build web --dart-define=BASE_URL=${BASE_URL} --release

# ============================================================
# Stage 2: Nginx - serve landing, admin, and proxy API
# ============================================================
FROM nginx:alpine

# Remove default config
RUN rm -f /etc/nginx/conf.d/default.conf

# Copy built admin web app from stage 1
COPY --from=admin-builder /app/krushikranti_admin/build/web /usr/share/nginx/html/admin

# Copy landing page (static HTML/CSS/JS - no build step)
COPY krushikranti-landing-page /usr/share/nginx/html/landing

# Copy APK file to landing page downloads directory
# NOTE: APK should be built and placed in krushikranti-landing-page/downloads/ before building this image
COPY krushikranti-landing-page/downloads/krushi-kranti-farmer.apk /usr/share/nginx/html/landing/downloads/krushi-kranti-farmer.apk

# Nginx config: landing (krushikranti.ltd, www), admin, API proxy
# SSL cert paths expect host to mount: -v /etc/letsencrypt:/etc/letsencrypt:ro
COPY frontend/nginx.conf /etc/nginx/conf.d/default.conf

# Ensure correct permissions for nginx
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
