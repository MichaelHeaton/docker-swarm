# DNS Architecture Summary

## Overview

This document summarizes the DNS naming convention and network architecture for Docker Swarm services.

## DNS Naming Convention

### Service Names (Public Access via Traefik on VLAN 5)

**Format**: `{service-name}.specterrealm.com`

**Purpose**: User-facing services accessible from VLAN 5 (Family) and other VLANs through Traefik

**Examples**:
- `portainer.specterrealm.com` → Portainer UI (via Traefik)
- `blocker.specterrealm.com` → AdGuard Home (via Traefik)
- `streaming.specterrealm.com` → Streaming service (via Traefik)

**DNS Records**: These should be **CNAME records** pointing to `traefik.specterrealm.com`

### Management Names (Direct Access from VLAN 15)

**Format**: `{service-name}-mgmt.specterrealm.com`

**Purpose**: Direct management access from VLAN 15 (Management network) only. **NOT for end users.**

**Examples**:
- `portainer-mgmt.specterrealm.com` → Direct Portainer access (VLAN 15 only)
- `adguard-mgmt.specterrealm.com` → Direct AdGuard access (VLAN 15 only)

**DNS Records**: These should be **A records** pointing to the service's management IP (172.16.15.x)

## Network Architecture

### Traefik (Reverse Proxy)

**Primary Interface (VLAN 5)**:
- **DNS**: `traefik.specterrealm.com`
- **IP**: `172.16.5.x` (Family VLAN)
- **Purpose**: Main entry point for all user-facing services
- **Access**: VLAN 5 (Family), VLAN 101 (Guest), Public Internet
- **Note**: All service CNAMEs point here

**Management Interface (VLAN 15)**:
- **DNS**: `traefik-mgmt.specterrealm.com`
- **IP**: `172.16.15.x` (Management VLAN)
- **Purpose**: Management/Admin access to Traefik dashboard
- **Access**: VLAN 15 (Management) only

### Service Routing Flow

1. **End User (VLAN 5)** requests `portainer.specterrealm.com`
2. **DNS resolves**: `portainer.specterrealm.com` → CNAME → `traefik.specterrealm.com` → A → `172.16.5.x`
3. **Traefik receives**: Request at `172.16.5.x:443` with Host header `portainer.specterrealm.com`
4. **Traefik routes**: To Portainer service on `mgmt-network` (VLAN 15)
5. **Response**: Returned to user via Traefik

### VLAN Isolation

- **VLAN 5 (Family)**: Can access VLAN 5 and Internet only. Cannot access VLAN 15 or other VLANs.
- **VLAN 15 (Management)**: Can access all VLANs for management purposes.
- **Traefik**: Acts as the proxy gateway, allowing VLAN 5 users to access services on VLAN 15 without direct network access.

## Required DNS Records

### Traefik A Records

| DNS Name | Type | IP | Purpose |
|----------|------|-----|---------|
| `traefik.specterrealm.com` | A | `172.16.5.x` | Main entry point (VLAN 5) |
| `traefik-mgmt.specterrealm.com` | A | `172.16.15.x` | Management access (VLAN 15) |

### Service CNAME Records (Point to Traefik)

| Service DNS Name | Type | Points To | Purpose |
|-----------------|------|-----------|---------|
| `portainer.specterrealm.com` | CNAME | `traefik.specterrealm.com` | Portainer UI |
| `blocker.specterrealm.com` | CNAME | `traefik.specterrealm.com` | AdGuard Home |
| `streaming.specterrealm.com` | CNAME | `traefik.specterrealm.com` | Streaming service |
| `secrets.specterrealm.com` | CNAME | `traefik.specterrealm.com` | Vault |
| `database.specterrealm.com` | CNAME | `traefik.specterrealm.com` | PostgreSQL |
| `observability.specterrealm.com` | CNAME | `traefik.specterrealm.com` | Grafana |
| `home.specterrealm.com` | CNAME | `traefik.specterrealm.com` | Homepage |
| `auth.specterrealm.com` | CNAME | `traefik.specterrealm.com` | Teleport |

### Management A Records (Direct Access)

| DNS Name | Type | IP | Purpose |
|----------|------|-----|---------|
| `portainer-mgmt.specterrealm.com` | A | `172.16.15.x` | Direct Portainer (VLAN 15) |
| `adguard-mgmt.specterrealm.com` | A | `172.16.15.x` | Direct AdGuard (VLAN 15) |

## Key Principles

1. **No Subdomains**: Use dashes, not dots (e.g., `adguard-mgmt.specterrealm.com`, not `adguard.mgmt.specterrealm.com`)
2. **Service Names**: Use generic service names (e.g., `blocker.specterrealm.com` for AdGuard, not `adguard.specterrealm.com`)
3. **CNAME to Traefik**: All user-facing services use CNAMEs pointing to `traefik.specterrealm.com`
4. **VLAN 5 Entry Point**: Traefik must be accessible on VLAN 5 (172.16.5.x) for end users
5. **Management Access**: `-mgmt` names are for VLAN 15 direct access only, not for end users

