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
# Stage 3: Build Farmer App (Android APK)
# ============================================================
FROM ghcr.io/cirruslabs/flutter:stable AS farmer-builder

WORKDIR /app
COPY krushikranti_farmer /app/krushikranti_farmer
WORKDIR /app/krushikranti_farmer

ARG BASE_URL=https://api.krushikranti.ltd
ENV BASE_URL=${BASE_URL}

RUN flutter pub get && \
    flutter build apk --dart-define=BASE_URL=${BASE_URL} --release

# ============================================================
# Stage 4: Nginx - serve landing, admin, hiring, and proxy API
# ============================================================
FROM nginx:alpine

ARG APK_FILENAME=krushi-kranti-farmer.apk
ARG NGINX_CONF=frontend/nginx.conf

RUN rm -f /etc/nginx/conf.d/default.conf

COPY --from=admin-builder /app/krushikranti_admin/build/web /usr/share/nginx/html/admin
COPY --from=hiring-builder /app/krushikranti-hiring/build/web /usr/share/nginx/html/hiring

COPY krushikranti-landing-page /usr/share/nginx/html/landing

# Dynamically update index.html so the download button points to the correct test or prod APK
RUN sed -i "s|krushi-kranti-farmer\.apk|${APK_FILENAME}|g" /usr/share/nginx/html/landing/index.html

# Copy the dynamically built APK from Stage 3 into the downloads folder
# and dynamically name it based on the APK_FILENAME argument passed by docker-compose!
COPY --from=farmer-builder /app/krushikranti_farmer/build/app/outputs/flutter-apk/app-release.apk /usr/share/nginx/html/landing/downloads/${APK_FILENAME}

COPY ${NGINX_CONF} /etc/nginx/conf.d/default.conf

RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
