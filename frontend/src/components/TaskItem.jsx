// This component is a form for adding new tasks. It includes fields for the task title, description, and due date.

const TaskItem = ({ task, onDelete, onToggle }) => {
  return (
    <div className={`task-item ${task.completed ? 'completed' : ''}`}>
      <div className="task-info" onClick={() => onToggle(task._id)}>
        <h3>{task.title}</h3>
        {task.description && <p>{task.description}</p>}
        {task.dueDate && (
          <p className="due-date">
            Due: {new Date(task.dueDate).toLocaleDateString()}
          </p>
        )}
      </div>
      <button 
        className="delete-btn" 
        onClick={() => onDelete(task._id)}
      >
        Delete
      </button>
    </div>
  );
};

export default TaskItem;