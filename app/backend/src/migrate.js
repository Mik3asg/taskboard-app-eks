// Standalone migration script — run as a Kubernetes Job before deploying
// the backend, so the schema is ready before any pod starts serving traffic.
//
// Usage:  node src/migrate.js
require('dotenv').config()
const { Pool } = require('pg')

const pool = new Pool({ connectionString: process.env.DATABASE_URL })

async function migrate() {
  console.log('Running migrations...')
  await pool.query(`
    CREATE TABLE IF NOT EXISTS tasks (
      id          SERIAL PRIMARY KEY,
      title       VARCHAR(255) NOT NULL,
      description TEXT         DEFAULT '',
      done        BOOLEAN      DEFAULT false,
      created_at  TIMESTAMP    DEFAULT NOW()
    )
  `)
  console.log('Migrations complete')
  await pool.end()
}

migrate().catch((err) => {
  console.error('Migration failed:', err)
  process.exit(1)
})
