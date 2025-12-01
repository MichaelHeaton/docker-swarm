# Minecraft Homepage Link Note

## Issue

Minecraft is a **game server**, not a web service. It doesn't have a web interface or URL that can be accessed via a browser.

## Current Configuration

The Homepage currently shows:
- **Minecraft**: `minecraft://` protocol link
- **Description**: "Minecraft Java Edition server (connect via game client)"

## Limitations

1. **`minecraft://` protocol**: This protocol link won't work in a web browser. It's designed to open the Minecraft game client, but browsers don't support this protocol by default.

2. **No Web Interface**: Minecraft servers don't have a web dashboard or management interface by default.

3. **Status Monitoring**: We can't use Uptime Kuma to monitor Minecraft via HTTP/HTTPS since it's a game server protocol (TCP port 25565).

## Options for Future

### Option 1: Remove from Homepage
- Remove Minecraft from the Homepage entirely
- Users connect directly via Minecraft client using the server IP/domain

### Option 2: Add Minecraft Map Viewer
- Deploy a Minecraft map viewer (e.g., `bluemap`, `dynmap`, `pl3xmap`)
- These provide a web interface to view the Minecraft world map
- Link would point to the map viewer URL (e.g., `https://minecraft-map.specterrealm.com`)

### Option 3: Add Minecraft Server Management Tool
- Deploy a Minecraft server management tool (e.g., `Pterodactyl`, `MCSManager`)
- These provide a web interface to manage the Minecraft server
- Link would point to the management interface

### Option 4: Keep as Placeholder
- Keep the current `minecraft://` link as a placeholder
- Add a note that users should connect via the Minecraft game client
- Consider adding the server IP/domain in the description

## Recommendation

**Short-term**: Keep the current configuration with a note that it's for reference only (users connect via game client).

**Long-term**: Deploy a Minecraft map viewer (e.g., `dynmap`) to provide a web interface that can be monitored and accessed via Homepage.

## Server Information

- **Server**: Minecraft01 (VM 103 on GPU01)
- **Status**: Running (needs repair)
- **IP**: See `specs-homelab/reference/common-values.md`
- **Port**: 25565 (default Minecraft port)
- **Version**: Java Edition

