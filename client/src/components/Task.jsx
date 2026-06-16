import React from "react";
import { FaTimes, FaStar, FaRegStar } from "react-icons/fa";
import { useI18n } from "../contexts/I18nContext.jsx";

const Task = ({ task, onDelete, onToggle }) => {
  const { t } = useI18n();
  return (
    <div
      className={`task ${task.importante ? "reminder" : ""}`}
      onDoubleClick={() => onToggle(task.uuid)}
    >
      <div className="task-content">
        <h3>{task.titulo}</h3>
        <p className="task-date">
          📅 {task.dia_atividade || t.noDate}
        </p>
      </div>
      <div className="task-actions">
        <button
          className="task-priority"
          onClick={() => onToggle(task.uuid)}
          title={task.importante ? t.removeImportant : t.markImportant}
        >
          {task.importante ? <FaStar /> : <FaRegStar />}
        </button>
        <button
          className="task-delete"
          onClick={() => onDelete(task.uuid)}
          title={t.delete}
        >
          <FaTimes />
        </button>
      </div>
    </div>
  );
};

export default Task;
