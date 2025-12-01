# DNS Records Setup for Docker Swarm Services

## Required DNS Records

You need to create the following DNS A records in Cloudflare (or your DNS provider) pointing to your Traefik service:

### Service Domains

1. **portainer.specterrealm.com**
   - Type: A
   - Value: Any Swarm manager node IP (recommended: 172.16.15.13 - swarm-pi5-01)
   - TTL: Auto (or 300 seconds)
   - Proxy: Enabled (orange cloud) - Recommended for Cloudflare protection

2. **traefik.specterrealm.com** (Default VLAN)
   - Type: A
   - Value: Any Swarm manager node IP (recommended: 172.16.15.13 - swarm-pi5-01)
   - TTL: Auto (or 300 seconds)
   - Proxy: Enabled (orange cloud) - Recommended for Cloudflare protection
   - Note: This is the default Traefik endpoint

3. **traefik-internal.specterrealm.com** (Family VLAN - Internal)
   - Type: A
   - Value: **172.16.5.9** (Traefik static IP on Family network - see note below)
   - TTL: Auto (or 300 seconds)
   - Proxy: Disabled (grey cloud) - Internal only, direct access
   - Note: This is the internal Traefik endpoint for Family VLAN (172.16.5.0/24)
   - **IMPORTANT**: Docker Swarm overlay networks don't support static IPs. To get 172.16.5.9, you'll need to either:
     - Use macvlan networks (not well-supported in Swarm mode)
     - Use host networking mode with VLAN interfaces
     - Or configure a macvlan network separately and connect Traefik to it

## Important Notes

### Traefik Ingress Mode
- Traefik is deployed with `mode: ingress` for ports 80 and 443
- This means Traefik is accessible on **any Swarm node's IP address** on ports 80/443
- The Swarm ingress network automatically routes traffic to the Traefik service
- You can point DNS to any of these IPs:
  - 172.16.15.13 (swarm-pi5-01 - Leader)
  - 172.16.15.14 (swarm-pi5-02 - Manager)
  - 172.16.15.15 (swarm-pi5-03 - Manager)

### Cloudflare DNS Challenge
- Traefik is configured to use Cloudflare DNS challenge for Let's Encrypt certificates
- This means Traefik will automatically create/update DNS TXT records for certificate validation
- Make sure your Cloudflare API token has the following permissions:
  - Zone:Read
  - DNS:Edit
- The API token is set via the `CF_API_TOKEN` environment variable

### Recommended Setup
1. Point both domains to the Swarm leader IP (172.16.15.13) for consistency
2. Enable Cloudflare proxy (orange cloud) for:
   - DDoS protection
   - SSL/TLS encryption
   - CDN benefits
3. If you want direct access (bypass Cloudflare), disable proxy (grey cloud)

### Testing DNS
After creating the records, verify they resolve:
```bash
# Check DNS resolution
nslookup portainer.specterrealm.com
nslookup traefik.specterrealm.com

# Test HTTP access (should redirect to HTTPS)
curl -I http://portainer.specterrealm.com

# Test HTTPS access
curl -I https://portainer.specterrealm.com
```

## Future Services
As you add more services to the Swarm, you'll need to create additional DNS records for each service domain configured in Traefik labels.

