#!/bin/bash
set -e

# Namespace opcional
NAMESPACE=default

# Nombre del release
RELEASE_NAME=edc-studio

# Instalar o actualizar el chart
if helm status "$RELEASE_NAME" -n "$NAMESPACE" > /dev/null 2>&1; then
  echo "Release $RELEASE_NAME ya existe. Haciendo upgrade..."
  helm upgrade "$RELEASE_NAME" ./edc-studio-helm -f ./edc-studio-helm/values.yaml -n "$NAMESPACE"
else
  echo "Instalando release $RELEASE_NAME..."
  helm install "$RELEASE_NAME" ./edc-studio-helm -f ./edc-studio-helm/values.yaml -n "$NAMESPACE"
fi

echo "Despliegue completado."