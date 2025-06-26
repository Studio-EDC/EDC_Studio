# Runtime Folder

This folder is used to store dynamically generated runtime data for each EDC Connector.

## ⚠️ Do Not Commit

Do **not** commit the contents of this folder to Git. Each subdirectory contains temporary or environment-specific configuration that is created at runtime.

## Structure

Each subfolder corresponds to a specific EDC Connector instance and typically contains:

- EDC configuration files
- Generated credentials (keystore, certificates, etc.)
- Docker volumes and logs

## Purpose

The `runtime` folder is mounted into the backend container and used to store connector-related configurations that vary per deployment.

## Git Ignore

Make sure your `.gitignore` file includes the following line:

```gitignore
runtime/*
```