import { useState, useEffect } from 'react'

const API = '/api/tasks'

export default function App() {
  const [tasks, setTasks]       = useState([])
  const [title, setTitle]       = useState('')
  const [description, setDesc]  = useState('')
  const [loading, setLoading]   = useState(true)
  const [error, setError]       = useState(null)

  const fetchTasks = async () => {
    try {
      const res = await fetch(API)
      if (!res.ok) throw new Error('Failed to load tasks')
      setTasks(await res.json())
    } catch (e) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { fetchTasks() }, [])

  const addTask = async (e) => {
    e.preventDefault()
    await fetch(API, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title, description }),
    })
    setTitle('')
    setDesc('')
    fetchTasks()
  }

  const toggleDone = async (task) => {
    await fetch(`${API}/${task.id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ...task, done: !task.done }),
    })
    fetchTasks()
  }

  const deleteTask = async (id) => {
    await fetch(`${API}/${id}`, { method: 'DELETE' })
    fetchTasks()
  }

  return (
    <div className="app">
      <header>
        <h1>TaskBoard</h1>
        <p className="subtitle">React + Node.js + PostgreSQL + Redis on EKS</p>
      </header>

      <form onSubmit={addTask} className="form">
        <input
          value={title}
          onChange={e => setTitle(e.target.value)}
          placeholder="Task title"
          required
        />
        <input
          value={description}
          onChange={e => setDesc(e.target.value)}
          placeholder="Description (optional)"
        />
        <button type="submit">Add Task</button>
      </form>

      {error   && <p className="error">{error}</p>}
      {loading && <p className="loading">Loading...</p>}

      {!loading && tasks.length === 0 && (
        <p className="empty">No tasks yet — add one above.</p>
      )}

      <ul className="task-list">
        {tasks.map(task => (
          <li key={task.id} className={task.done ? 'done' : ''}>
            <span className="toggle" onClick={() => toggleDone(task)}>
              {task.done ? '✅' : '⬜'}
            </span>
            <div className="content">
              <strong>{task.title}</strong>
              {task.description && <p>{task.description}</p>}
            </div>
            <button className="delete" onClick={() => deleteTask(task.id)}>✕</button>
          </li>
        ))}
      </ul>
    </div>
  )
}
