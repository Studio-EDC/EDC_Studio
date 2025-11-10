# EDC Studio · Dockerized Environment

This project provides a complete development and deployment environment for **EDC Studio**, composed of the following services:

- **MongoDB** as the main database.
- **Postgres** as the main database of the EDCs.
- **Backend** built with Python and FastAPI.
- **Data Pond** as a microservice for data management or transformation.
- **Frontend** built with Flutter Web.

---

## 🐳 Docker Compose Architecture

```yaml
services:
  mongo:         # MongoDB
  postgres:      # BBDD EDCs
  backend:       # Principal API of the EDC Studio system
  data_pond:     # Additional microservice to store files
  frontend:      # Graphic interface for the user
```
---

## 📁 Project Structure

```csharp
runtime/
  ├── 685bba5d800fd3e2d89bb...     # Dynamically generated directories (DO NOT commit to Git)
  ├── 685cf1d30531139e715751...
├── docker-compose.local.yml           # Main orchestration file for local environment
├── docker-compose.prod.yml           # Main orchestration file for prod environment
├── .env                            # environment variables
├── .env.frontend                 # environment variables for frontend
├── start_local.sh                      # Initialization script for local environment
├── start_prod.sh                      # Initialization script for prod environment
└── README.md                    
```

---

## 🚀 How to Start the Environment

Run the initialization script:

```bash
./start_local.sh   
```

or

```bash
./start_prod.sh   
```

This:
- Starts all containers defined in docker-compose.yml.

---

## ⚙️ Environment Configuration

Before running the production environment, make sure to configure your **Nginx** and **Let's Encrypt** variables in the `.env` file:

```bash
# Nginx / Let's Encrypt
VIRTUAL_HOST_BACKEND=backend.example.com
VIRTUAL_HOST_DATAPOND=datapond.example.com
VIRTUAL_HOST_FRONTEND=app.example.com

VIRTUAL_PORT_BACKEND=8000
VIRTUAL_PORT_DATAPOND=8001
VIRTUAL_PORT_FRONTEND=3000

LETSENCRYPT_EMAIL=admin@example.com
```

These variables are required for automatic reverse proxy and HTTPS certificate generation through **nginx-proxy** and **letsencrypt-nginx-proxy-companion**.

💡 **Tip:** In local mode, these variables are not used.  
The containers are accessed directly through `localhost` and their exposed ports instead of domain names.

---

## 🌐 Access to the services

Once the environment is up and running, the services will be available at:

- **Frontend**: http://localhost:3000
- **Backend**: http://localhost:8000
- **Data Pond**: http://localhost:8001
- **MongoDB**: mongodb://localhost:27017

---

## 📝 Notas

- Folders inside `runtime/` are generated dynamically and should not be committed to Git.
- All containers use the `linux/amd64` platform to ensure cross-platform compatibility.
- The external network `edc_network` must exist before running `docker-compose`, but the `start.sh` script will create it automatically if needed.
