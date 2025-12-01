# Traefik VLAN 5 Access - Ready for DNS Update

## ✅ Configuration Complete

**VLAN 5 IP configured on `swarm-pi5-01`:**
- Interface: `eth0.5`
- IP Address: `172.16.5.13/24`
- Gateway: `172.16.5.1`
- Status: ✅ Active and reachable

## How It Works

1. **Docker Swarm Ingress**: Traefik uses `mode: ingress` for ports 80/443
2. **Traffic Routing**: When users on VLAN 5 access `172.16.5.13:80/443`, Docker Swarm ingress network automatically routes the traffic to the Traefik service
3. **Multi-homed Node**: `swarm-pi5-01` is now accessible on both:
   - VLAN 15 (Management): `172.16.15.13`
   - VLAN 5 (Family): `172.16.5.13`

## Next Steps

### 1. Update DNS Record

In UniFi DNS settings, update:
- **Domain**: `traefik.specterrealm.com`
- **Type**: A (Host)
- **IP Address**: `172.16.5.13`
- **TTL**: Auto

### 2. Set Cloudflare API Token

The Cloudflare API token is still missing. You need to set it so SSL certificates can be obtained:

```bash
# On swarm-pi5-02 (or any manager node)
# Option 1: Update service directly
docker service update --env-add "CLOUDFLARE_DNS_API_TOKEN=your-token-here" traefik_traefik

# Option 2: Create .env file and redeploy
echo "CF_API_TOKEN=your-token-here" > ~/.env
cd /path/to/stacks
source ~/.env
docker stack deploy -c traefik.yml traefik
```

### 3. Wait for SSL Certificates

After setting the Cloudflare token, wait 2-5 minutes for Let's Encrypt to issue SSL certificates.

### 4. Test Access

From a device on VLAN 5:
```bash
# Should redirect to HTTPS
curl -L http://traefik.specterrealm.com

# Should show Traefik dashboard
curl -k https://traefik.specterrealm.com
```

## Services That Will Work

Once DNS and SSL are configured, all these services will be accessible from VLAN 5:
- ✅ `https://traefik.specterrealm.com` - Traefik dashboard
- ✅ `https://portainer.specterrealm.com` - Portainer
- ✅ `https://blocker.specterrealm.com` - AdGuard Home
- ✅ `https://home.specterrealm.com` - Homepage Family
- ✅ `https://admin.specterrealm.com` - Homepage Admin
- ✅ `https://status.specterrealm.com` - Uptime Kuma

## Current Status

- ✅ VLAN 5 IP configured: `172.16.5.13/24` on `swarm-pi5-01`
- ✅ Docker Swarm ingress routing configured
- ✅ Traefik service running with ingress mode
- ⏳ DNS record needs update: `traefik.specterrealm.com` → `172.16.5.13`
- ⏳ Cloudflare API token needs to be set for SSL certificates

