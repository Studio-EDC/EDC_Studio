#!/bin/bash

# Crea la red solo si no existe
if ! docker network ls --format '{{.Name}}' | grep -wq edc-network; then
  echo "Creando red externa 'edc-network'..."
  docker network create edc-network
fi

# Arranca los servicios
docker compose up