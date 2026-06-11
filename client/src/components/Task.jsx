import React from "react";
import { FaTimes, FaStar, FaRegStar } from "react-icons/fa";

const Task = ({ task, onDelete, onToggle }) => {
  return (
    <div
      className={`task ${task.importante ? "reminder" : ""}`}
      onDoubleClick={() => onToggle(task.uuid)}
    >
      <div className="task-content">
        <h3>{task.titulo}</h3>
        <p className="task-date">
          📅 {task.dia_atividade || "No date set"}
        </p>
      </div>
      <div className="task-actions">
        <button
          className="task-priority"
          onClick={() => onToggle(task.uuid)}
          title={task.importante ? "Remove important" : "Mark as important"}
        >
          {task.importante ? <FaStar /> : <FaRegStar />}
        </button>
        <button
          className="task-delete"
          onClick={() => onDelete(task.uuid)}
          title="Delete"
        >
          <FaTimes />
        </button>
      </div>
    </div>
  );
};

export default Task;
