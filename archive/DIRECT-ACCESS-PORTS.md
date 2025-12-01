# Direct Access Ports for Testing

## Portainer
- **Port**: 9000 (host mode)
- **Direct Access**: `http://172.16.15.13:9000` (or any Swarm manager IP)
- **Status**: ✅ Working - Access directly to bypass Traefik

## Traefik
- **API/Dashboard Port**: 8080 (host mode)  
- **Direct Access**: `http://172.16.15.13:8080/dashboard/` (or any Swarm manager IP)
- **Status**: ⚠️ Currently being reconfigured

## Testing Commands

```bash
# Test Portainer (should work)
curl http://172.16.15.13:9000

# Test Traefik API
curl http://172.16.15.13:8080/ping
# Should return: OK

# Test Traefik Dashboard
curl http://172.16.15.13:8080/dashboard/
# Should return HTML if working

# Test Traefik Routers
curl http://172.16.15.13:8080/api/http/routers
# Should return JSON list of routers
```

## Current Issues

1. **Traefik API**: Was set to `--api.insecure=false` which requires routing
2. **Docker API Version**: Errors preventing service discovery
3. **Routers**: May not be created due to Docker provider issues

## Next Steps

1. ✅ Portainer restarted - should be accessible on port 9000
2. ⏳ Traefik redeployed with `--api.insecure=true` - testing now
3. ⏳ Verify routers are being created
4. ⏳ Test routing through Traefik

