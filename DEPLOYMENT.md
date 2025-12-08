# Docker Swarm Deployment Guide

## Environment Variables

Traefik requires a Cloudflare API token for SSL certificate issuance. This is stored in a `.env` file that is **NOT** tracked by Git.

### Setup

1. Copy the example file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and add your Cloudflare API token:
   ```
   CF_API_TOKEN=your-token-here
   TRAEFIK_TIMEZONE=UTC
   ```

3. Deploy stacks using the `.env` file:
   ```bash
   # On your local machine (for testing)
   export $(cat .env | xargs)
   docker stack deploy -c stacks/traefik.yml traefik

   # On swarm-pi5-01 (production)
   ssh packer@swarm-pi5-01
   export $(cat ~/.env | xargs)
   docker stack deploy -c /path/to/traefik.yml traefik
   ```

### Security Notes

- `.env` is in `.gitignore` and will never be committed
- Keep your `.env` file secure and don't share it
- Rotate tokens if they're ever exposed
