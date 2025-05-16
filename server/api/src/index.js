const express = require('express');
const Redis = require('ioredis');
const { v4: uuidv4 } = require('uuid');
const rateLimit = require('express-rate-limit');
const basicAuth = require('express-basic-auth');
const { body, validationResult } = require('express-validator');
const winston = require('winston');

// Configure logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: '/app/logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: '/app/logs/combined.log' })
  ]
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple()
  }));
}

const app = express();
app.use(express.json());

// Redis connection
const redis = new Redis(process.env.REDIS_URL);

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Basic authentication
app.use(basicAuth({
  users: { 'admin': process.env.API_PASSWORD || 'changeme' },
  challenge: true
}));

class TunnelManager {
  constructor() {
    this.redis = redis;
    this.logger = logger;
  }

  async createTunnel() {
    const tunnelId = uuidv4();
    const subdomain = await this.generateSubdomain();
    
    const tunnel = {
      id: tunnelId,
      subdomain,
      status: 'active',
      createdAt: new Date().toISOString(),
      port: await this.allocatePort()
    };

    await this.redis.hset(`tunnel:${tunnelId}`, tunnel);
    await this.redis.sadd('active_tunnels', tunnelId);
    
    this.logger.info('Created new tunnel', { tunnelId, subdomain });
    return tunnel;
  }

  async generateSubdomain() {
    const subdomain = Math.random().toString(36).substring(2, 8);
    const exists = await this.redis.sismember('used_subdomains', subdomain);
    
    if (exists) {
      return this.generateSubdomain();
    }
    
    await this.redis.sadd('used_subdomains', subdomain);
    return subdomain;
  }

  async allocatePort() {
    const usedPorts = await this.redis.smembers('used_ports');
    let port = 2000;
    
    while (usedPorts.includes(port.toString())) {
      port++;
    }
    
    await this.redis.sadd('used_ports', port.toString());
    return port;
  }

  async getTunnel(tunnelId) {
    const tunnel = await this.redis.hgetall(`tunnel:${tunnelId}`);
    return tunnel;
  }

  async deleteTunnel(tunnelId) {
    const tunnel = await this.getTunnel(tunnelId);
    if (tunnel) {
      await this.redis.del(`tunnel:${tunnelId}`);
      await this.redis.srem('active_tunnels', tunnelId);
      await this.redis.srem('used_ports', tunnel.port);
      await this.redis.srem('used_subdomains', tunnel.subdomain);
      this.logger.info('Deleted tunnel', { tunnelId });
    }
  }
}

const tunnelManager = new TunnelManager();

// Routes
app.post('/api/tunnels', [
  body('port').optional().isInt({ min: 1, max: 65535 }),
  body('subdomain').optional().isAlphanumeric()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const tunnel = await tunnelManager.createTunnel();
    res.json(tunnel);
  } catch (error) {
    logger.error('Error creating tunnel', { error: error.message });
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/tunnels/:id', async (req, res) => {
  try {
    const tunnel = await tunnelManager.getTunnel(req.params.id);
    if (!tunnel) {
      return res.status(404).json({ error: 'Tunnel not found' });
    }
    res.json(tunnel);
  } catch (error) {
    logger.error('Error getting tunnel', { error: error.message });
    res.status(500).json({ error: error.message });
  }
});

app.delete('/api/tunnels/:id', async (req, res) => {
  try {
    await tunnelManager.deleteTunnel(req.params.id);
    res.status(204).send();
  } catch (error) {
    logger.error('Error deleting tunnel', { error: error.message });
    res.status(500).json({ error: error.message });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  logger.info(`API server running on port ${PORT}`);
}); 