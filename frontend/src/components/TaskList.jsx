import TaskItem from './TaskItem';

const TaskList = ({ tasks, onDelete, onToggle }) => {
  if (tasks.length === 0) {
    return <p className="no-tasks">No tasks to show</p>;
  }

  return (
    <div className="task-list">
      {tasks.map((task) => (
        <TaskItem
          key={task._id}
          task={task}
          onDelete={onDelete}
          onToggle={onToggle}
        />
      ))}
    </div>
  );
};

export default TaskList;