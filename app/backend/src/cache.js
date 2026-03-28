const redis = require('redis')

const client = redis.createClient({
  url: process.env.REDIS_URL || 'redis://redis:6379',
})

client.on('error', (err) => console.error('Redis error:', err))

// Connect once at module load — all routes share this connection
client.connect()

module.exports = client
