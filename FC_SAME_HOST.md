Expose the Datagora Federated Catalog under the existing backend host:

- Catalog API:
  `https://api.edcstudio.datagora.eu/fc/v1alpha/catalog/query`
- Health:
  `https://api.edcstudio.datagora.eu/fc-health/check/health`
- Startup:
  `https://api.edcstudio.datagora.eu/fc-health/check/startup`

Requirements:

1. The federated catalog container must be attached to `edc_network`.
2. Its container name must stay `datagora_federated_catalog`.
3. `docker-compose.prod.yml` must mount `./nginx/vhost.d:/etc/nginx/vhost.d`
   so the custom route file is picked up by `jwilder/nginx-proxy`.

After copying the new file `nginx/vhost.d/api.edcstudio.datagora.eu`, restart:

- `nginx-proxy`
- `letsencrypt-nginx-proxy-companion`

No DNS change is needed because the existing host is reused.
