const express = require('express')
const router  = express.Router()
const { pool } = require('../db')
const cache    = require('../cache')

const CACHE_KEY = 'tasks:all'
const CACHE_TTL = 60 // seconds

// GET /api/tasks — returns all tasks, served from Redis cache when available
router.get('/', async (req, res) => {
  try {
    const cached = await cache.get(CACHE_KEY)
    if (cached) return res.json(JSON.parse(cached))

    const { rows } = await pool.query(
      'SELECT * FROM tasks ORDER BY created_at DESC'
    )
    await cache.setEx(CACHE_KEY, CACHE_TTL, JSON.stringify(rows))
    res.json(rows)
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

// POST /api/tasks — create a new task, invalidate cache
router.post('/', async (req, res) => {
  const { title, description = '' } = req.body
  if (!title) return res.status(400).json({ error: 'title is required' })

  try {
    const { rows } = await pool.query(
      'INSERT INTO tasks (title, description) VALUES ($1, $2) RETURNING *',
      [title, description]
    )
    await cache.del(CACHE_KEY)
    res.status(201).json(rows[0])
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

// PUT /api/tasks/:id — update title, description, or done status; invalidate cache
router.put('/:id', async (req, res) => {
  const { id } = req.params
  const { title, description, done } = req.body

  try {
    const { rows } = await pool.query(
      'UPDATE tasks SET title=$1, description=$2, done=$3 WHERE id=$4 RETURNING *',
      [title, description, done, id]
    )
    if (!rows.length) return res.status(404).json({ error: 'Task not found' })

    await cache.del(CACHE_KEY)
    res.json(rows[0])
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

// DELETE /api/tasks/:id — remove task, invalidate cache
router.delete('/:id', async (req, res) => {
  const { id } = req.params

  try {
    await pool.query('DELETE FROM tasks WHERE id=$1', [id])
    await cache.del(CACHE_KEY)
    res.status(204).send()
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

module.exports = router
