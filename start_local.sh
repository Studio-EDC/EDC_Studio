#!/bin/bash

set -e

ENV_FILE=".env"
FRONTEND_ENV=".env.frontend"
COMPOSE_FILE="docker-compose.yml"

echo "🔧 Setting up local environment..."

# --- 1. Detect if macOS or Linux ---
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_INPLACE=("sed" "-i" "")
else
  SED_INPLACE=("sed" "-i")
fi

# --- 2. Remove Nginx block from .env ---
if grep -q "# Nginx" "$ENV_FILE"; then
  echo "🧹 Removing Nginx configuration block from .env..."
  "${SED_INPLACE[@]}" '/# Nginx/,+10d' "$ENV_FILE"
else
  echo "ℹ️  No Nginx block found in .env."
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

# --- 5. Detect actual ports for backend and data_pond ---
get_port() {
  local service=$1
  grep -A 5 "$service:" "$COMPOSE_FILE" | grep 'ports:' -A 1 | tail -n 1 | sed -E 's/.*"([0-9]+):[0-9]+".*/\1/'
}

BACKEND_PORT=$(get_port "backend")
DATA_POND_PORT=$(get_port "data_pond")

if [ -z "$BACKEND_PORT" ] || [ -z "$DATA_POND_PORT" ]; then
  echo "⚠️  Could not detect ports automatically. Using default values."
  BACKEND_PORT=8000
  DATA_POND_PORT=8001
fi

echo "📡 Backend exposed on localhost:$BACKEND_PORT"
echo "💧 Data Pond exposed on localhost:$DATA_POND_PORT"

# --- 6. Write local endpoints into .env.frontend ---
echo "📝 Setting local endpoints in $FRONTEND_ENV..."
cat > "$FRONTEND_ENV" <<EOL
ENDPOINT_BASE=http://localhost:${BACKEND_PORT}
ENDPOINT_DATA_POND=http://localhost:${DATA_POND_PORT}
EOL

# --- 7. Start Docker containers ---
echo "🚀 Starting containers in local mode..."
docker compose -f docker-compose.local.yml pull
docker compose -f docker-compose.local.yml up -d

echo "✅ Local environment successfully started."
