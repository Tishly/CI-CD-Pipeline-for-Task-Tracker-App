import { useState, useEffect } from 'react';
import TaskList from './components/TaskList';
import TaskForm from './components/TaskForm';
import Header from './components/Header';
import './app.css';

function App() {
  const [tasks, setTasks] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);
  
  // API base URL - would come from environment variables in production
  const API_URL = 'http://localhost:5000/api/tasks';
  
  // Fetch tasks from API
  useEffect(() => {
    const fetchTasks = async () => {
      try {
        setIsLoading(true);
        const response = await fetch(API_URL);
        
        if (!response.ok) {
          throw new Error(`Server responded with status: ${response.status}`);
        }
        
        const data = await response.json();
        setTasks(data);
        setError(null);
      } catch (err) {
        setError('Failed to fetch tasks. Please try again later.');
        console.error('Error fetching tasks:', err);
      } finally {
        setIsLoading(false);
      }
    };

    fetchTasks();
  }, []);

  // Add new task
  const addTask = async (task) => {
    try {
      const response = await fetch(API_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(task),
      });

      if (!response.ok) {
        throw new Error(`Server responded with status: ${response.status}`);
      }

      const newTask = await response.json();
      setTasks([...tasks, newTask]);
    } catch (err) {
      setError('Failed to add task. Please try again.');
      console.error('Error adding task:', err);
    }
  };

  // Delete task
  const deleteTask = async (id) => {
    try {
      const response = await fetch(`${API_URL}/${id}`, {
        method: 'DELETE',
      });

      if (!response.ok) {
        throw new Error(`Server responded with status: ${response.status}`);
      }

      setTasks(tasks.filter(task => task._id !== id));
    } catch (err) {
      setError('Failed to delete task. Please try again.');
      console.error('Error deleting task:', err);
    }
  };

  // Toggle task completion status
  const toggleComplete = async (id) => {
    try {
      const taskToUpdate = tasks.find(task => task._id === id);
      const updatedTask = { ...taskToUpdate, completed: !taskToUpdate.completed };
      
      const response = await fetch(`${API_URL}/${id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(updatedTask),
      });

      if (!response.ok) {
        throw new Error(`Server responded with status: ${response.status}`);
      }

      const returnedTask = await response.json();
      
      setTasks(
        tasks.map(task => 
          task._id === id ? returnedTask : task
        )
      );
    } catch (err) {
      setError('Failed to update task. Please try again.');
      console.error('Error updating task:', err);
    }
  };

  return (
    <div className="container">
      <Header />
      {error && <div className="error-message">{error}</div>}
      <TaskForm onAdd={addTask} />
      {isLoading ? (
        <p>Loading tasks...</p>
      ) : (
        <TaskList 
          tasks={tasks} 
          onDelete={deleteTask} 
          onToggle={toggleComplete} 
        />
      )}
    </div>
  );
}

export default App;