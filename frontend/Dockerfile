# ============================================================
# Stage 1: Build Admin (Flutter web)
# ============================================================
FROM ghcr.io/cirruslabs/flutter:stable AS admin-builder

WORKDIR /app

COPY krushikranti_admin /app/krushikranti_admin
WORKDIR /app/krushikranti_admin

# API base URL — overridden per environment via docker-compose build args
ARG BASE_URL=https://api.krushikranti.ltd
ENV BASE_URL=${BASE_URL}

RUN flutter pub get && \
    flutter build web --dart-define=BASE_URL=${BASE_URL} --release

# ============================================================
# Stage 2: Nginx - serve landing, admin, and proxy API
# ============================================================
FROM nginx:alpine

# APK filename — overridden per environment via docker-compose build args
#   prod:  krushi-kranti-farmer.apk        (built with BASE_URL=api.krushikranti.ltd)
#   test:  krushi-kranti-farmer-test.apk   (built with BASE_URL=api2.krushikranti.ltd)
ARG APK_FILENAME=krushi-kranti-farmer.apk

RUN rm -f /etc/nginx/conf.d/default.conf

COPY --from=admin-builder /app/krushikranti_admin/build/web /usr/share/nginx/html/admin

COPY krushikranti-landing-page /usr/share/nginx/html/landing

# Copy the environment-specific APK and always serve it as krushi-kranti-farmer.apk
COPY krushikranti-landing-page/downloads/${APK_FILENAME} /usr/share/nginx/html/landing/downloads/krushi-kranti-farmer.apk

COPY frontend/nginx.conf /etc/nginx/conf.d/default.conf

RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
