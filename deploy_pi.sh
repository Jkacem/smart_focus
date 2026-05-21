#!/bin/bash
# =============================================================
# SmartFocus Backend — Script de déploiement Raspberry Pi 5
# Usage : bash deploy_pi.sh
# =============================================================

set -e  # Arrêt immédiat en cas d'erreur

BACKEND_DIR="$(cd "$(dirname "$0")/backend" && pwd)"
SERVICE_NAME="smartfocus"
VENV_DIR="$BACKEND_DIR/venv_pi"
DB_NAME="smartFocus_db"
DB_USER="smartfocus"
PI_USER="$(whoami)"

echo "========================================"
echo "  SmartFocus — Déploiement Raspberry Pi"
echo "========================================"
echo ""

# ── 1. Dépendances système ────────────────────────────────────
echo "[1/6] Installation des dépendances système..."
sudo apt update
sudo apt install -y \
    python3 python3-pip python3-venv python3-dev \
    libpq-dev build-essential \
    postgresql postgresql-contrib \
    git curl

# ── 2. PostgreSQL ─────────────────────────────────────────────
echo ""
echo "[2/6] Configuration de PostgreSQL..."

sudo systemctl enable postgresql
sudo systemctl start postgresql

# Création de l'utilisateur et de la base (ignore si déjà existants)
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD 'changeme_password';"

sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE DATABASE \"$DB_NAME\" OWNER $DB_USER;"

echo "   Base de données '$DB_NAME' prête."

# ── 3. Environnement Python ───────────────────────────────────
echo ""
echo "[3/6] Création de l'environnement virtuel Python..."

python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

pip install --upgrade pip wheel setuptools

echo "   Installation des dépendances Python (peut prendre 10-20 min)..."
pip install -r "$BACKEND_DIR/requirements_pi.txt"

deactivate

# ── 4. Fichier .env ───────────────────────────────────────────
echo ""
echo "[4/6] Configuration du fichier .env..."

ENV_FILE="$BACKEND_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
    SECRET_KEY=$(openssl rand -hex 32)
    PI_API_KEY=$(openssl rand -hex 32)

    cat > "$ENV_FILE" << EOF
# PostgreSQL
DATABASE_URL=postgresql://$DB_USER:changeme_password@localhost:5432/$DB_NAME

# JWT
SECRET_KEY=$SECRET_KEY
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# Server
HOST=0.0.0.0
PORT=8000
DEBUG=False

# CORS — ajoute l'IP de tes appareils si nécessaire
CORS_ORIGINS=http://localhost:3000

# Pi client shared secret
PI_API_KEY=$PI_API_KEY

# LLM provider: "gemini" ou "groq"
AI_PROVIDER=groq
GROQ_API_KEY=REMPLACE_PAR_TA_CLE_GROQ
GROQ_MODEL=llama-3.3-70b-versatile
GEMINI_MODEL=gemini-2.5-flash
LLM_MAX_RPM=25

# Google
GOOGLE_API_KEY=REMPLACE_PAR_TA_CLE_GOOGLE
GOOGLE_OAUTH_CLIENT_IDS=REMPLACE_PAR_TON_CLIENT_ID

# Storage
CHROMA_DB_PATH=chroma_db
UPLOADS_DIR=uploads
EOF

    echo "   Fichier .env créé. IMPORTANT : édite $ENV_FILE et remplis les clés API."
else
    echo "   Fichier .env déjà existant, non modifié."
fi

# ── 5. Service systemd ────────────────────────────────────────
echo ""
echo "[5/6] Création du service systemd..."

sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null << EOF
[Unit]
Description=SmartFocus Backend API
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=$PI_USER
WorkingDirectory=$BACKEND_DIR
ExecStart=$VENV_DIR/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=on-failure
RestartSec=5
EnvironmentFile=$ENV_FILE

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable ${SERVICE_NAME}.service

# ── 6. Démarrage ──────────────────────────────────────────────
echo ""
echo "[6/6] Démarrage du service..."
sudo systemctl start ${SERVICE_NAME}.service

sleep 3
STATUS=$(sudo systemctl is-active ${SERVICE_NAME}.service)

echo ""
echo "========================================"
if [ "$STATUS" = "active" ]; then
    PI_IP=$(hostname -I | awk '{print $1}')
    echo "  Déploiement réussi !"
    echo ""
    echo "  Backend accessible sur :"
    echo "  http://$PI_IP:8000"
    echo ""
    echo "  Pour l'app Flutter, builder avec :"
    echo "  flutter build apk --dart-define=API_BASE_URL=http://$PI_IP:8000"
    echo ""
    echo "  Logs : sudo journalctl -u $SERVICE_NAME -f"
else
    echo "  Le service n'a pas démarré correctement."
    echo "  Vérifier les logs : sudo journalctl -u $SERVICE_NAME -n 50"
fi
echo "========================================"
