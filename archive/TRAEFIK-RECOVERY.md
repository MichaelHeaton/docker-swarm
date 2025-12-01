# Traefik Recovery Instructions

## Issue

Traefik was updated with an empty Cloudflare token, causing services to fail. Traefik has been rolled back and is running again, but the Cloudflare token needs to be restored.

## Current Status

✅ Traefik is running (rolled back to previous version)
❌ Cloudflare token is empty (needs to be restored)

## Fix

Redeploy Traefik from the stack file with the `.env` file sourced:

```bash
# SSH to swarm-pi5-01
ssh packer@swarm-pi5-01

# Navigate to where your stacks are (adjust path as needed)
cd /path/to/stacks  # or wherever traefik.yml and .env are located

# Source the .env file and redeploy
source .env
docker stack deploy -c traefik.yml traefik
```

## Verify

After redeploying, verify the token is set:

```bash
docker service inspect traefik_traefik --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' | grep CLOUDFLARE
```

Should show: `CLOUDFLARE_DNS_API_TOKEN=<your-token>`

## Services Should Recover

Once Traefik is redeployed with the correct token:
- SSL certificates will be issued for all domains
- All services should become accessible again
- Uptime Kuma monitors should start working (after DNS fix is deployed)

## Note

The rollback restored Traefik to a working state, but without the Cloudflare token, SSL certificates won't be issued for new domains. Redeploying with the token will fix this.

