# ---------- Etapa 1: compilar la app Flutter para web ----------
FROM debian:bookworm-slim AS build

# Versión de Flutter (debe cumplir con el "sdk:" de pubspec.yaml)
ARG FLUTTER_VERSION=3.47.9

RUN apt-get update \
 && apt-get install -y --no-install-recommends git curl unzip xz-utils ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"
RUN flutter config --no-analytics --enable-web && flutter precache --web

WORKDIR /app

# Copiar primero las dependencias para aprovechar la caché de Docker
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copiar el resto del código
COPY . .

# Agregar soporte web si el proyecto aún no lo tiene y compilar
RUN ([ -d web ] || flutter create --platforms=web .) \
 && flutter build web --release

# ---------- Etapa 2: servir con Nginx ----------
FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
