# LocalTunnel Server

A self-hosted implementation of the LocalTunnel server.

## Prerequisites

- Docker and Docker Compose
- OpenSSL (for generating SSL certificates)
- Node.js 18+ (for development)

## Quick Start

1. Generate SSL certificates:
   ```bash
   # On Linux/Mac:
   ./manage.sh ssl

   # On Windows:
   .\manage.ps1 ssl
   ```

2. Start the services:
   ```bash
   # On Linux/Mac:
   ./manage.sh start

   # On Windows:
   .\manage.ps1 start
   ```

## Management Scripts

The project includes management scripts for both Linux/Mac (`manage.sh`) and Windows (`manage.ps1`) to simplify common operations.

### Available Commands

```bash
# Show help
./manage.sh help
# or
.\manage.ps1 help

# Start services in production mode
./manage.sh start
# or
.\manage.ps1 start

# Start services in development mode
./manage.sh start dev
# or
.\manage.ps1 start dev

# Stop services
./manage.sh stop
# or
.\manage.ps1 stop

# Restart services
./manage.sh restart
# or
.\manage.ps1 restart

# Show logs (all services)
./manage.sh logs
# or
.\manage.ps1 logs

# Show logs for specific service
./manage.sh logs api
# or
.\manage.ps1 logs api

# Check service status
./manage.sh status
# or
.\manage.ps1 status

# Generate SSL certificates
./manage.sh ssl
# or
.\manage.ps1 ssl

# Clean up (remove all containers and volumes)
./manage.sh cleanup
# or
.\manage.ps1 cleanup
```

## Services

The server consists of the following services:

- **API Service** (port 3000): Handles tunnel creation and management
- **Proxy Service** (ports 80, 443, 2000-3000): Manages TCP connections
- **Redis** (port 6379): Stores tunnel state
- **Nginx** (ports 80, 443): Handles SSL termination and routing

## API Endpoints

1. Create a new tunnel:
   ```bash
   curl -X POST http://localhost:3000/api/tunnels
   ```

2. Get tunnel information:
   ```bash
   curl http://localhost:3000/api/tunnels/{tunnel_id}
   ```

3. Delete a tunnel:
   ```bash
   curl -X DELETE http://localhost:3000/api/tunnels/{tunnel_id}
   ```

## Development

1. Install dependencies:
   ```bash
   cd api && npm install
   cd ../proxy && npm install
   ```

2. Start services in development mode:
   ```bash
   # On Linux/Mac:
   ./manage.sh start dev

   # On Windows:
   .\manage.ps1 start dev
   ```

3. View logs:
   ```bash
   # On Linux/Mac:
   ./manage.sh logs

   # On Windows:
   .\manage.ps1 logs
   ```

## Security Features

- Basic authentication is enabled by default (username: admin, password: dev_password)
- Rate limiting is enabled (100 requests per 15 minutes per IP)
- SSL/TLS encryption is required for all connections
- Docker container isolation
- Redis persistence for tunnel state

## Project Structure

```
server/
├── api/                    # API service
│   ├── src/
│   ├── Dockerfile
│   └── Dockerfile.dev
├── proxy/                  # TCP proxy service
│   ├── src/
│   ├── Dockerfile
│   └── Dockerfile.dev
├── nginx/                  # Nginx configuration
│   ├── conf.d/
│   └── ssl/
├── scripts/               # Utility scripts
│   ├── generate-ssl.sh
│   └── generate-ssl.bat
├── logs/                  # Log files
├── docker-compose.yml     # Production compose file
├── docker-compose.dev.yml # Development compose file
├── manage.sh             # Linux/Mac management script
├── manage.ps1            # Windows management script
└── README.md
```

## Troubleshooting

1. Check service status:
   ```bash
   # On Linux/Mac:
   ./manage.sh status

   # On Windows:
   .\manage.ps1 status
   ```

2. View service logs:
   ```bash
   # On Linux/Mac:
   ./manage.sh logs [service_name]

   # On Windows:
   .\manage.ps1 logs [service_name]
   ```

3. Restart services:
   ```bash
   # On Linux/Mac:
   ./manage.sh restart

   # On Windows:
   .\manage.ps1 restart
   ```

4. Clean up and start fresh:
   ```bash
   # On Linux/Mac:
   ./manage.sh cleanup
   ./manage.sh start

   # On Windows:
   .\manage.ps1 cleanup
   .\manage.ps1 start
   ```

## Common Issues

1. **SSL Certificate Issues**
   - Regenerate certificates using the management script
   - Ensure certificates are in the correct location

2. **Port Conflicts**
   - Check if ports 80, 443, 3000, and 2000-3000 are available
   - Stop any services using these ports

3. **Docker Issues**
   - Ensure Docker is running
   - Check Docker logs for errors
   - Try restarting Docker

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT 