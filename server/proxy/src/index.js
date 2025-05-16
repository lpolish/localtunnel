const net = require('net');
const Redis = require('ioredis');
const winston = require('winston');

// Configure logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: '/app/logs/proxy-error.log', level: 'error' }),
    new winston.transports.File({ filename: '/app/logs/proxy-combined.log' })
  ]
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple()
  }));
}

class TCPProxy {
  constructor() {
    this.redis = new Redis(process.env.REDIS_URL);
    this.servers = new Map();
    this.logger = logger;
  }

  async start() {
    // Listen for new tunnel requests
    this.redis.subscribe('new_tunnel', (err) => {
      if (err) {
        this.logger.error('Redis subscription error:', err);
        return;
      }
      this.logger.info('Subscribed to new_tunnel channel');
    });

    this.redis.on('message', async (channel, message) => {
      if (channel === 'new_tunnel') {
        try {
          const tunnel = JSON.parse(message);
          await this.createProxyServer(tunnel);
        } catch (error) {
          this.logger.error('Error processing tunnel message:', error);
        }
      }
    });

    // Load existing tunnels
    await this.loadExistingTunnels();
  }

  async loadExistingTunnels() {
    try {
      const activeTunnels = await this.redis.smembers('active_tunnels');
      for (const tunnelId of activeTunnels) {
        const tunnel = await this.redis.hgetall(`tunnel:${tunnelId}`);
        if (tunnel) {
          await this.createProxyServer(tunnel);
        }
      }
      this.logger.info(`Loaded ${activeTunnels.length} existing tunnels`);
    } catch (error) {
      this.logger.error('Error loading existing tunnels:', error);
    }
  }

  async createProxyServer(tunnel) {
    const server = net.createServer((clientSocket) => {
      this.logger.info('New client connection', {
        tunnelId: tunnel.id,
        clientAddress: clientSocket.remoteAddress
      });

      const localSocket = new net.Socket();
      
      localSocket.connect(tunnel.port, 'localhost', () => {
        this.logger.debug('Connected to local server', {
          tunnelId: tunnel.id,
          port: tunnel.port
        });

        clientSocket.pipe(localSocket);
        localSocket.pipe(clientSocket);
      });

      localSocket.on('error', (err) => {
        this.logger.error('Local socket error:', {
          tunnelId: tunnel.id,
          error: err.message
        });
        clientSocket.end();
      });

      clientSocket.on('error', (err) => {
        this.logger.error('Client socket error:', {
          tunnelId: tunnel.id,
          error: err.message
        });
        localSocket.end();
      });

      clientSocket.on('close', () => {
        this.logger.debug('Client connection closed', {
          tunnelId: tunnel.id
        });
      });

      localSocket.on('close', () => {
        this.logger.debug('Local connection closed', {
          tunnelId: tunnel.id
        });
      });
    });

    server.on('error', (err) => {
      this.logger.error('Server error:', {
        tunnelId: tunnel.id,
        error: err.message
      });
    });

    server.listen(tunnel.port, () => {
      this.logger.info('Proxy server listening', {
        tunnelId: tunnel.id,
        port: tunnel.port
      });
      this.servers.set(tunnel.id, server);
    });
  }

  async stopTunnel(tunnelId) {
    const server = this.servers.get(tunnelId);
    if (server) {
      server.close(() => {
        this.logger.info('Stopped proxy server', { tunnelId });
        this.servers.delete(tunnelId);
      });
    }
  }
}

const proxy = new TCPProxy();
proxy.start().catch(error => {
  logger.error('Failed to start proxy:', error);
  process.exit(1);
}); 