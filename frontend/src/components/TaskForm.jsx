import { useState } from 'react';

const TaskForm = ({ onAdd }) => {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [dueDate, setDueDate] = useState('');

  const handleSubmit = (e) => {
    e.preventDefault();
    
    if (!title) {
      alert('Please add a task title');
      return;
    }
    
    onAdd({
      title,
      description,
      dueDate,
      completed: false
    });
    
    // Clear form
    setTitle('');
    setDescription('');
    setDueDate('');
  };

  return (
    <form className="task-form" onSubmit={handleSubmit}>
      <div className="form-control">
        <label htmlFor="title">Task Title</label>
        <input
          type="text"
          id="title"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Add Task Title"
        />
      </div>
      
      <div className="form-control">
        <label htmlFor="description">Description</label>
        <textarea
          id="description"
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          placeholder="Add Description"
        />
      </div>
      
      <div className="form-control">
        <label htmlFor="date">Due Date</label>
        <input
          type="date"
          id="date"
          value={dueDate}
          onChange={(e) => setDueDate(e.target.value)}
        />
      </div>
      
      <button type="submit" className="btn">Add Task</button>
    </form>
  );
};

export default TaskForm;