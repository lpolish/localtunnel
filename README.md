# LocalTunnel

LocalTunnel exposes your localhost to the world for easy testing and sharing! No need to mess with DNS or deploy just to have others test out your changes.

Great for working with browser testing tools like browserling or external api callback services like twilio which require a public url for callbacks.

## Features

- Expose local servers to the internet
- Custom subdomain support
- Automatic reconnection
- Health monitoring
- SSL/TLS support
- Self-hosted server option
- Multiple client implementations
- Vercel deployment support

## Quick Start

### Using the Public Service

```bash
# Install globally
npm install -g localtunnel

# Start a tunnel
lt --port 3000
```

### Self-Hosted Server

#### Option 1: Local Deployment

1. Clone the repository:
   ```bash
   git clone https://github.com/lpolish/localtunnel.git
   cd localtunnel
   ```

2. Start the server:
   ```bash
   cd server
   
   # Generate SSL certificates
   ./manage.sh ssl  # Linux/Mac
   # or
   .\manage.ps1 ssl  # Windows
   
   # Start services
   ./manage.sh start  # Linux/Mac
   # or
   .\manage.ps1 start  # Windows
   ```

#### Option 2: Vercel Deployment

1. Fork this repository to your GitHub account

2. Install Vercel CLI:
   ```bash
   npm install -g vercel
   ```

3. Set up environment variables in Vercel:
   ```bash
   vercel env add REDIS_URL
   vercel env add DOMAIN
   vercel env add SSL_KEY_PATH
   vercel env add SSL_CERT_PATH
   ```

4. Deploy to Vercel:
   ```bash
   cd server
   vercel
   ```

5. Set up a custom domain in Vercel:
   - Go to your project settings in Vercel
   - Add your domain under "Domains"
   - Follow Vercel's DNS configuration instructions

6. Configure SSL:
   - Vercel provides automatic SSL certificates
   - No need to manage SSL certificates manually

7. Use the client with your Vercel deployment:
   ```bash
   # Run the client script directly
   node localtunnel.js --port 3000 --host https://your-vercel-domain
   ```

### Using the Client

**Option 1: Run directly (no installation)**
```bash
# Run the client script directly
node localtunnel.js --port 3000 --host https://your-server-domain
# or using the CLI script
node bin/lt.js --port 3000 --host https://your-server-domain
```

**Option 2: Install locally**
```bash
# Install dependencies
npm install

# Run the client
npm start -- --port 3000 --host https://your-server-domain
# or
node bin/lt.js --port 3000 --host https://your-server-domain
```

**Option 3: Install globally (from local source)**
```bash
# Install from local directory
npm install -g .

# Run the client
lt --port 3000 --host https://your-server-domain
```

## Installation

### Client

#### Local Installation (Recommended for Development)
```bash
# Clone the repository
git clone https://github.com/lpolish/localtunnel.git
cd localtunnel

# Install dependencies
npm install

# Run directly
node localtunnel.js --port 3000 --host https://your-server-domain
# or
node bin/lt.js --port 3000 --host https://your-server-domain
```

#### Global Installation
```bash
npm install -g localtunnel
```

#### As a dependency in your project
```bash
yarn add localtunnel
```

### Server

#### Local Deployment
See the [server documentation](server/README.md) for detailed setup instructions.

#### Vercel Deployment
1. Fork the repository
2. Set up environment variables in Vercel:
   - `REDIS_URL`: Your Redis instance URL
   - `DOMAIN`: Your custom domain
   - `SSL_KEY_PATH`: Path to SSL key (managed by Vercel)
   - `SSL_CERT_PATH`: Path to SSL certificate (managed by Vercel)
3. Deploy using Vercel CLI or connect your GitHub repository
4. Configure your custom domain in Vercel
5. SSL certificates are automatically managed by Vercel

## Client Usage

### CLI

When using the client, you can start a tunnel in several ways:

```bash
# Using the global installation
lt --port 8000

# Using the local installation
node localtunnel.js --port 8000

# Using the CLI script directly
node bin/lt.js --port 8000
```

That's it! It will connect to the tunnel server, setup the tunnel, and tell you what url to use for your testing. This url will remain active for the duration of your session.

You can restart your local server all you want, the client is smart enough to detect this and reconnect once it is back.

### Common Arguments

- `--subdomain` request a named subdomain on the localtunnel server (default is random characters)
- `--local-host` proxy to a hostname other than localhost
- `--max-reconnect` maximum number of reconnection attempts (default is 10)
- `--reconnect-backoff` initial delay in ms between reconnection attempts (doubles with each attempt, default is 1000ms)
- `--detailed-logs` enable detailed request logging with timestamps and headers
- `--status-monitor` display periodic connection status updates
- `--request-log-size` maximum number of requests to keep in memory (default is 100)
- `--host` URL for the upstream proxy server (defaults to https://localtunnel.me)

You may also specify arguments via env variables:

```bash
PORT=3000 node localtunnel.js
# or
PORT=3000 node bin/lt.js
```

### API

The localtunnel client is also usable through an API:

```js
const localtunnel = require('./localtunnel');  // Use local version
// or
const localtunnel = require('localtunnel');    // Use installed version

(async () => {
  const tunnel = await localtunnel({ 
    port: 3000,
    host: 'https://your-server-domain' // Optional: use your self-hosted server
  });

  // the assigned public url for your tunnel
  // i.e. https://abcdefgjhij.your-server-domain
  tunnel.url;

  // the current status of the tunnel
  const status = tunnel.getStatus();
  console.log(status.status); // 'connected'

  tunnel.on('status', (status) => {
    // status updates emitted periodically
    console.log(`Status: ${status.status}, Last activity: ${status.lastActive}`);
  });

  tunnel.on('request', (info) => {
    // requests going through the tunnel
    console.log(`${info.method} ${info.path}`);
  });

  tunnel.on('close', () => {
    // tunnels are closed
  });
})();
```

#### API Options

- `port` (number) [required] The local port number to expose through localtunnel.
- `subdomain` (string) Request a specific subdomain on the proxy server.
- `host` (string) URL for the upstream proxy server. Defaults to `https://localtunnel.me`.
- `local_host` (string) Proxy to this hostname instead of `localhost`.
- `local_https` (boolean) Enable tunneling to local HTTPS server.
- `local_cert` (string) Path to certificate PEM file for local HTTPS server.
- `local_key` (string) Path to certificate key file for local HTTPS server.
- `local_ca` (string) Path to certificate authority file for self-signed certificates.
- `allow_invalid_cert` (boolean) Disable certificate checks for your local HTTPS server.
- `maxReconnectAttempts` (number) Maximum number of reconnection attempts (default: 10).
- `reconnectBackoff` (number) Initial delay in ms between reconnection attempts (default: 1000ms).
- `maxRequestLogSize` (number) Maximum number of requests to keep in log history (default: 100).

### Events

The `tunnel` instance emits the following events:

| event           | args | description                                                                          |
| --------------- | ---- | ------------------------------------------------------------------------------------ |
| request         | info | fires when a request is processed by the tunnel, contains _method_, _path_, _id_ and _timestamp_ fields |
| error           | err  | fires when an error happens on the tunnel                                            |
| close           |      | fires when the tunnel has closed                                                     |
| connecting      |      | fires when the tunnel is attempting to connect                                       |
| connected       | info | fires when the tunnel is successfully connected, contains _url_ field               |
| reconnecting    | info | fires when tunnel is attempting to reconnect, contains _attempt_ and _delay_ fields |
| reconnected     | info | fires when tunnel has successfully reconnected, contains _url_ field                |
| reconnect_error | err  | fires when there's an error during reconnection                                     |
| status          | info | fires periodically with status information                                           |

### Methods

The `tunnel` instance has the following methods:

| method    | args | description                                                                |
| --------- | ---- | -------------------------------------------------------------------------- |
| close     |      | close the tunnel                                                           |
| getStatus |      | get the current status of the tunnel including connection state and stats  |

## Server

The server component is a self-hosted implementation of the LocalTunnel server. It includes:

- API service for tunnel management
- TCP proxy service for connection handling
- Redis for state management
- Nginx for SSL termination and routing

See the [server documentation](server/README.md) for detailed setup and configuration instructions.

## Other Clients

Clients in other languages:

- _go_ [gotunnelme](https://github.com/NoahShen/gotunnelme)
- _go_ [go-localtunnel](https://github.com/localtunnel/go-localtunnel)
- _C#/.NET_ [localtunnel-client](https://github.com/angelobreuer/localtunnel-client)
- _Rust_ [rlt](https://github.com/kaichaosun/rlt)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT

# Vercel Deployment Guide (Self-Hosted Server)

This section explains how to deploy both the static frontend and the API to Vercel, so your LocalTunnel page and API are available at your custom domain.

## Directory Structure

- `server/api/` — Node.js API service (Express)
- `server/public/` — Static frontend (HTML/CSS/JS)
- `server/vercel.json` — Vercel configuration

## Vercel Configuration (`server/vercel.json`)

```json
{
  "version": 2,
  "builds": [
    { "src": "api/src/index.js", "use": "@vercel/node" },
    { "src": "public/**/*", "use": "@vercel/static" }
  ],
  "routes": [
    { "src": "/api/(.*)", "dest": "api/src/index.js" },
    { "src": "/(.*)", "dest": "public/$1" }
  ],
  "env": {
    "NODE_ENV": "production",
    "REDIS_URL": "<your_redis_url>",
    "DOMAIN": "<your_custom_domain>",
    "API_PORT": "3000",
    "API_HOST": "0.0.0.0"
  }
}
```

- All `/api/*` requests are routed to the API service.
- All other requests serve static files from `public/`.

## Step-by-Step Deployment

1. **Fork and Clone the Repository**
   ```sh
   git clone https://github.com/yourusername/localtunnel.git
   cd localtunnel/server
   ```

2. **Prepare Environment Variables**
   - Copy `server/.env.vercel` to `.env` and fill in your values:
     - `REDIS_URL`: Use a managed Redis service (e.g., Upstash, Redis Cloud).
     - `DOMAIN`: Your Vercel custom domain (e.g., `mytunnel.vercel.app`).
     - `API_KEY`: (Optional) Set for API security.

3. **Install Vercel CLI**
   ```sh
   npm install -g vercel
   vercel login
   ```

4. **Deploy to Vercel**
   ```sh
   vercel --prod
   ```
   - Follow the prompts to link or create a new Vercel project.
   - Set environment variables in the Vercel dashboard if not using `.env`.

5. **Configure Custom Domain (Optional)**
   - In the Vercel dashboard, add your custom domain and point DNS records as instructed.

6. **Access Your Deployment**
   - Frontend: `https://<your-vercel-domain>/`
   - API: `https://<your-vercel-domain>/api/`

## Troubleshooting

- **API returns 404 or not found:**
  - Ensure the `vercel.json` routes are correct and the API is in `api/src/index.js`.
- **Static page not loading:**
  - Make sure your static files are in `public/` and referenced correctly.
- **Redis connection errors:**
  - Double-check your `REDIS_URL` and that your Redis instance allows connections from Vercel.
- **Environment variables not set:**
  - Set them in the Vercel dashboard under Project Settings > Environment Variables.

## Notes
- Vercel automatically provides SSL/TLS for your deployment.
- The proxy service (TCP forwarding) is not supported on Vercel; only the API and frontend are deployed. For full tunnel functionality, deploy the proxy on a VM or container platform.

---

For more details, see the `server/vercel.json` and `server/.env.vercel` files.
