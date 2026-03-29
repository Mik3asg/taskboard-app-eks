// TaskBoard backend entry point
require('dotenv').config()
const express    = require('express')
const cors       = require('cors')
const { initDB } = require('./db')
const tasksRouter = require('./routes/tasks')

const app  = express()
const PORT = process.env.PORT || 8000

app.use(cors())
app.use(express.json())

// Health check — used by Kubernetes liveness/readiness probes
app.get('/api/health', (req, res) => res.json({ status: 'ok' }))

app.use('/api/tasks', tasksRouter)

// Initialise the DB schema then start listening
initDB()
  .then(() => {
    app.listen(PORT, () => console.log(`Backend listening on port ${PORT}`))
  })
  .catch((err) => {
    console.error('Failed to initialise database:', err)
    process.exit(1)
  })
