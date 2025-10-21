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
├── docker-compose.yml           # Main orchestration file
├── init.sh                      # Initialization script
└── README.md                    
```

---

## ⚙️ Configuration

Before starting the environment, you must update the `RUNTIME_PATH` environment variable inside the `backend` service in the `docker-compose.yml` file:

```yaml
RUNTIME_PATH=/path/EDC_Studio/runtime
```

---

## 🚀 How to Start the Environment

Run the docker compose :

```bash
docker compose pull && docker compose up -d
```

This:
- Starts all containers defined in docker-compose.yml.

---

## 🌐 Acceso a los servicios

Once the environment is up and running, the services will be available at:

- **Frontend**: http://localhost:3000
- **Backend**: http://localhost:8000
- **Data Pond**: http://localhost:8001
- **MongoDB**: mongodb://localhost:27017

---

## 📝 Notas

- Folders inside `runtime/` are generated dynamically and should not be committed to Git.
- All containers use the `linux/amd64` platform to ensure cross-platform compatibility.
- The external network `edc-network` must exist before running `docker-compose`, but the `init.sh` script will create it automatically if needed.
