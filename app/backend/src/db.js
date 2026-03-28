const { Pool } = require('pg')

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
})

// Run on startup — creates the tasks table if it doesn't exist yet
async function initDB() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS tasks (
      id          SERIAL PRIMARY KEY,
      title       VARCHAR(255) NOT NULL,
      description TEXT         DEFAULT '',
      done        BOOLEAN      DEFAULT false,
      created_at  TIMESTAMP    DEFAULT NOW()
    )
  `)
  console.log('Database ready')
}

module.exports = { pool, initDB }
