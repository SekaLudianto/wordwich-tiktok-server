# syntax=docker/dockerfile:1
FROM node:20-slim

# Install Python + ffmpeg + yt-dlp dependencies
# yt-dlp di-install via pip (lebih up-to-date dari versi apt)
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        ffmpeg \
        ca-certificates \
        curl \
    && pip3 install --no-cache-dir --break-system-packages -U yt-dlp \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install node deps (cache layer)
COPY package*.json ./
RUN npm install --omit=dev

# Copy source
COPY . .

# Entrypoint: kalau env YT_COOKIES tersedia, tulis ke cookies.txt sebelum start
RUN printf '#!/bin/sh\nset -e\nif [ -n "$YT_COOKIES" ]; then\n  printf "%s" "$YT_COOKIES" > /app/cookies.txt\n  echo "[entrypoint] cookies.txt written ($(wc -l < /app/cookies.txt) lines)"\nfi\nexec "$@"\n' > /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["node", "server.js"]
