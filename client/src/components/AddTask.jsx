import React, { useState } from "react";
import Modal from "./Modal";

const AddTask = ({ onAdd }) => {
  const [titulo, setTitulo] = useState("");
  const [dia, setDia] = useState("");
  const [importante, setImportante] = useState(false);
  const [showModal, setShowModal] = useState(false);

  const onSubmit = (e) => {
    e.preventDefault();

    if (!titulo.trim()) {
      setShowModal(true);
      return;
    }

    onAdd({ 
      titulo: titulo.trim(), 
      dia_atividade: dia || new Date().toLocaleDateString('en-US'), 
      importante 
    });

    setTitulo("");
    setDia("");
    setImportante(false);
  };

  return (
    <form className="add-form" onSubmit={onSubmit}>
      <div className="form-control">
        <label>Task</label>
        <input
          type="text"
          placeholder="What do you need to do?"
          value={titulo}
          onChange={(e) => setTitulo(e.target.value)}
        />
      </div>
      
      <div className="form-control">
        <label>Date/Deadline</label>
        <input
          type="text"
          placeholder="When?"
          value={dia}
          onChange={(e) => setDia(e.target.value)}
        />
      </div>
      
      <div className="form-control-check">
        <input
          type="checkbox"
          id="importante"
          checked={importante}
          onChange={(e) => setImportante(e.target.checked)}
        />
        <label htmlFor="importante">Important</label>
      </div>
      
      <button type="submit" className="btn btn-block success">
        Add New Task
      </button>
      
      <Modal
        isOpen={showModal}
        onClose={() => setShowModal(false)}
        title="Required field"
        message="Please add a description for the task"
        type="warning"
      />
    </form>
  );
};

export default AddTask;
