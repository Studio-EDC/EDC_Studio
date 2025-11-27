#!/bin/bash

set -e

ENV_FILE=".env"
FRONTEND_ENV=".env.frontend"
COMPOSE_FILE="docker-compose.yml"

echo "🚀 Setting up production environment..."

# --- 1. Detect if macOS or Linux ---
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_INPLACE=("sed" "-i" "")
else
  SED_INPLACE=("sed" "-i")
fi

# --- 2. Add Nginx block to .env if not present ---
if ! grep -q "# Nginx" "$ENV_FILE"; then
  echo "🧩 Adding Nginx configuration block to ${ENV_FILE}..."
  cat >> "$ENV_FILE" <<EOL

# Nginx
VIRTUAL_HOST_BACKEND=example.backend.com
VIRTUAL_HOST_DATAPOND=example.datapond.com
VIRTUAL_HOST_FRONTEND=example.frontend.com

VIRTUAL_PORT_BACKEND=8000
VIRTUAL_PORT_DATAPOND=8001
VIRTUAL_PORT_FRONTEND=3000

LETSENCRYPT_EMAIL=admin@example.com
EOL
else
  echo "ℹ️  Nginx block already present in ${ENV_FILE}."
fi

# --- 3. Update RUNTIME_PATH dynamically ---
if grep -q "^RUNTIME_PATH=" "$ENV_FILE"; then
  echo "🛠️  Updating RUNTIME_PATH variable in ${ENV_FILE}..."
  CURRENT_PATH="$(pwd)/runtime"
  echo "   New value: ${CURRENT_PATH}"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|^RUNTIME_PATH=.*|RUNTIME_PATH=${CURRENT_PATH}|" "$ENV_FILE"
  else
    sed -i "s|^RUNTIME_PATH=.*|RUNTIME_PATH=${CURRENT_PATH}|" "$ENV_FILE"
  fi
else
  echo "ℹ️  Variable RUNTIME_PATH not found in ${ENV_FILE}, adding it at the end."
  echo "RUNTIME_PATH=$(pwd)/runtime" >> "$ENV_FILE"
fi

# --- 4. Create Docker network if it does not exist ---
if ! docker network ls --format '{{.Name}}' | grep -wq edc_network; then
  echo "🌐 Creating external network 'edc_network'..."
  docker network create edc_network
fi

# --- 5. Write production endpoints into .env.frontend ---
echo "🌍 Setting production endpoints in $FRONTEND_ENV..."

# Cargar variables del .env en el entorno actual
set -a
source "$ENV_FILE"
set +a

# Si faltan las variables, advertir
if [[ -z "$VIRTUAL_HOST_BACKEND" || -z "$VIRTUAL_HOST_DATAPOND" ]]; then
  echo "⚠️  Warning: VIRTUAL_HOST_BACKEND or VIRTUAL_HOST_DATAPOND not found in .env"
fi

cat > "$FRONTEND_ENV" <<EOL
ENDPOINT_BASE=https://${VIRTUAL_HOST_BACKEND}
EOL

echo "✅ .env.frontend updated with production endpoints:"
cat "$FRONTEND_ENV"

# --- 6. Start Docker containers ---
echo "🚢 Starting containers in production mode..."
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d

echo "✅ Production environment successfully started."