# Identity Hub

The **Identity Hub** is the decentralized identity management component of the UPCxels dataspace, based on [Eclipse Dataspace Components (EDC)](https://eclipse-edc.github.io). It manages digital identities, decentralized identifiers (DIDs), and credential issuance/verification within the dataspace.

This README is intended to help engineers **build, deploy, and use pre-built images** from the UPCxels registry.

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Building Locally](#building-locally)
4. [Using Docker Images](#using-docker-images)
5. [APIs and Documentation](#apis-and-documentation)
6. [Additional Resources](#additional-resources)

---

## Overview

The Identity Hub is one of the core components of UPCxels, including:

* **Connector Dataplane** – handles data transfer and enforcement
* **Connector Controlplane** – orchestrates contracts and transfers
* **Federated Catalog** – provides metadata discovery
* **Identity Hub** – manages decentralized identities and credentials
* **Issuer Service** – issues credentials
* **Runtime Embedded** – lightweight runtime environment

The Identity Hub can either be built from source or consumed as a pre-built Docker image from the UPCxels registry. It provides APIs for creating and managing DIDs, storing verifiable credentials, and interacting securely with other dataspace components.

---

## Prerequisites

Before building or running the Identity Hub:

* [Java 17+](https://adoptium.net/)
* [Gradle](https://gradle.org/install/) (or use the included wrapper)
* [Docker](https://docs.docker.com/get-docker/) for containerization
* Access to the UPCxels Docker registry (**credentials may be required**)

---

## Building Locally

### Step 1 – Generate the JAR

```bash
./gradlew clean build
```

> Produces the executable JAR under `build/libs/`.

### Step 2 – Create Docker Image

```bash
./gradlew dockerize -Ppersistence=true
```

* The `persistence` flag enables local storage for runtime state.
* The resulting image is tagged according to the Gradle `docker` configuration.

---

## Using Docker Images

You can pull the pre-built image directly from the **UPC Harbor Registry**:

```bash
docker pull registry.upc.edu/upcxels/identity-hub:latest
```

Then run it with:

```bash
docker run -d --name upcxels-identity-hub \
  -p 8383:8383 \
  registry.upc.edu/upcxels/identity-hub:latest
```

> Adjust ports, volumes, and environment variables as needed. The Identity Hub interacts with other UPCxels components such as the Controlplane and Issuer Service.

---

## APIs and Documentation

The Identity Hub exposes REST endpoints for managing decentralized identities and credentials.

* **EDC Identity Hub Project Repository** – [https://github.com/eclipse-edc/IdentityHub](https://github.com/eclipse-edc/IdentityHub)
* **Swagger API Documentation** – [https://eclipse-edc.github.io/IdentityHub/openapi/identity-api/#/](https://eclipse-edc.github.io/IdentityHub/openapi/identity-api/#/)
  Provides a full list of endpoints for DID management, credential storage, and verification.

For practical integration with other UPCxels components, see the [**Core Infra Deploy**](https://gitlab.upc.edu/upcxels/core-infra-deploy) repo.

---

## Additional Resources

* UPCxels GitLab registry: [https://gitlab.upc.edu/upcxels](https://gitlab.upc.edu/upcxels)
* EDC GitHub repo: [https://eclipse-edc.github.io/](https://eclipse-edc.github.io/)
* Guides on building and deploying dataspace components: [UPCxels internal wiki](https://gitlab.upc.edu/upcxels/apis-documentation)

---

### Optional: CI/CD

The `.gitlab-ci.yaml` pipeline automatically builds and pushes images to the UPC Harbor Registry on commits to `main`. You can trigger it manually if needed.
