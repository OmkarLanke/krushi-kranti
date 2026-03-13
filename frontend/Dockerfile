# ============================================================
# Stage 1: Build Admin (Flutter web)
# ============================================================
FROM ghcr.io/cirruslabs/flutter:stable AS admin-builder

WORKDIR /app
COPY krushikranti_admin /app/krushikranti_admin
WORKDIR /app/krushikranti_admin

ARG BASE_URL=https://api.krushikranti.ltd
ENV BASE_URL=${BASE_URL}

RUN flutter pub get && \
    flutter build web --dart-define=BASE_URL=${BASE_URL} --release

# ============================================================
# Stage 2: Build Hiring portal (Flutter web)
# ============================================================
FROM ghcr.io/cirruslabs/flutter:stable AS hiring-builder

WORKDIR /app
COPY krushikranti-hiring /app/krushikranti-hiring
WORKDIR /app/krushikranti-hiring

ARG BASE_URL=https://api.krushikranti.ltd
ENV BASE_URL=${BASE_URL}

RUN flutter pub get && \
    flutter build web --dart-define=BASE_URL=${BASE_URL} --release

# ============================================================
# Stage 3: Nginx - serve landing, admin, hiring, and proxy API
# ============================================================
FROM nginx:alpine

ARG APK_FILENAME=krushi-kranti-farmer.apk
ARG NGINX_CONF=frontend/nginx.conf

RUN rm -f /etc/nginx/conf.d/default.conf

COPY --from=admin-builder /app/krushikranti_admin/build/web /usr/share/nginx/html/admin
COPY --from=hiring-builder /app/krushikranti-hiring/build/web /usr/share/nginx/html/hiring

COPY krushikranti-landing-page /usr/share/nginx/html/landing

COPY krushikranti-landing-page/downloads/${APK_FILENAME} /usr/share/nginx/html/landing/downloads/krushi-kranti-farmer.apk

COPY ${NGINX_CONF} /etc/nginx/conf.d/default.conf

RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
