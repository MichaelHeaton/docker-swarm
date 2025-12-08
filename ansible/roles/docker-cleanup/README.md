# Docker Cleanup Role

Automatically cleans up stopped Docker containers to prevent disk space issues and container buildup.

## Purpose

Docker Swarm creates new containers when updating services, leaving old stopped containers behind. This role sets up an automated cleanup process to remove these stopped containers on a schedule.

## Variables

| Variable                  | Default                         | Description                      |
| ------------------------- | ------------------------------- | -------------------------------- |
| `docker_cleanup_enabled`  | `true`                          | Enable/disable automatic cleanup |
| `docker_cleanup_schedule` | `"0 2 * * *"`                   | Cron schedule (daily at 2 AM)    |
| `docker_cleanup_log_file` | `"/var/log/docker-cleanup.log"` | Log file path                    |

## Usage

### Basic Usage (Default Schedule)

```yaml
- role: docker-cleanup
```

This will:

- Run cleanup daily at 2 AM
- Log to `/var/log/docker-cleanup.log`
- Remove all stopped containers

### Custom Schedule

```yaml
- role: docker-cleanup
  vars:
    docker_cleanup_schedule: "0 3 * * 0" # Weekly on Sunday at 3 AM
```

### Custom Log Location

```yaml
- role: docker-cleanup
  vars:
    docker_cleanup_log_file: "/var/log/docker/cleanup.log"
```

### Disable Cleanup

```yaml
- role: docker-cleanup
  vars:
    docker_cleanup_enabled: false
```

## Cron Schedule Format

The schedule uses standard cron format: `minute hour day month weekday`

Examples:

- `"0 2 * * *"` - Daily at 2 AM (default)
- `"0 3 * * 0"` - Weekly on Sunday at 3 AM
- `"0 */6 * * *"` - Every 6 hours
- `"0 2 1 * *"` - First day of month at 2 AM

## What Gets Cleaned

The cleanup command `docker container prune -f` removes:

- All stopped containers
- Unused container networks (if using `docker system prune`)
- Frees up disk space

**Note**: Only stopped containers are removed. Running containers are never affected.

## Logging

Cleanup operations are logged to the specified log file. Check logs with:

```bash
tail -f /var/log/docker-cleanup.log
```

## Manual Cleanup

You can manually run cleanup at any time:

```bash
docker container prune -f
```

## Integration

This role is automatically included in `swarm-setup.yml` playbook with the `docker` and `cleanup` tags.

Run only cleanup role:

```bash
ansible-playbook playbooks/swarm-setup.yml --tags cleanup
```

Run all Docker-related tasks including cleanup:

```bash
ansible-playbook playbooks/swarm-setup.yml --tags docker
```
