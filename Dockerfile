# --- STAGE 1: Compilare Frontend ---
FROM node:lts AS frontend-builder
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ .
RUN npm run build

# --- STAGE 2: Runtime Backend ---
FROM python:3.11-slim
WORKDIR /app

# [STRETCH - CACHE PIP LAYERS & SHRINK IMAGE]
# Copiem requirements separat pentru a folosi cache-ul Docker eficient
COPY backend/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copiem restul backend-ului
COPY backend/ .

# Copiem frontend-ul în locația corectă pe care o caută Flask
COPY --from=frontend-builder /app/frontend/dist ./frontend/dist

ENV HOST=0.0.0.0
EXPOSE 8000

# [STRETCH - ADD A HEALTHCHECK]
# Îi spune lui Docker cum să verifice automat dacă containerul e blocat sau viu
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8000/health || exit 1

CMD ["python", "-m", "app"]