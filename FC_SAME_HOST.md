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

## Multi-FC Phase 1

For a path-based rollout with one `catalog-datagora` runtime per Datagora,
reuse the same public host and mount additional `location` blocks in the same
vhost file.

Examples:

- `https://api.edcstudio.datagora.eu/fc-agro/v1alpha/catalog/query`
- `https://api.edcstudio.datagora.eu/fc-mobility/v1alpha/catalog/query`
- `https://api.edcstudio.datagora.eu/fc-health-agro/check/health`

Do not reuse the single-runtime container name `datagora_federated_catalog` in
that model. Each runtime must use its own container name and route prefix, for
example:

- `datagora_federated_catalog_agro` with `/fc-agro/`
- `datagora_federated_catalog_mobility` with `/fc-mobility/`

The file
`nginx/vhost.d/api.edcstudio.datagora.eu.multi-fc.example`
contains the expected route shape. The script
`federated-catalog-local-work-012/scripts/scaffold-multi-fc-runtime.sh`
generates the exact `location` blocks per Datagora.
