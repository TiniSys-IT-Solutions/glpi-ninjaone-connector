# Security Policy

## Supported versions

Security fixes are provided for the latest published release and the current
`main` branch.

## Reporting a vulnerability

Do not disclose suspected vulnerabilities, credentials or tokens in a public
issue. Use GitHub's private vulnerability reporting feature and include the
affected version, impact, reproduction steps and any suggested mitigation.

## Deployment guidance

- Use a dedicated NinjaOne Services API application with the minimum required
  scope.
- Restrict plugin configuration to trusted GLPI administrators.
- Use HTTPS and protect the GLPI database, which contains connector secrets.
- Validate the connector against a non-production tenant before deployment.
- Back up GLPI files and its database before installing or upgrading plugins.

Application-level encryption of stored NinjaOne secrets remains a documented
hardening objective. Treat database backups as sensitive material.
