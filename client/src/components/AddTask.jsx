import React, { useState } from "react";
import Modal from "./Modal";
import { useI18n } from "../contexts/I18nContext.jsx";

const AddTask = ({ onAdd }) => {
  const { t } = useI18n();
  const [titulo, setTitulo] = useState("");
  const [dia, setDia] = useState("");
  const [importante, setImportante] = useState(false);
  const [showModal, setShowModal] = useState(false);

  const onSubmit = (e) => {
    e.preventDefault();
    if (!titulo.trim()) { setShowModal(true); return; }
    onAdd({ titulo: titulo.trim(), dia_atividade: dia || new Date().toLocaleDateString("en-US"), importante });
    setTitulo("");
    setDia("");
    setImportante(false);
  };

  return (
    <form className="add-form" onSubmit={onSubmit}>
      <div className="form-control">
        <label>{t.task}</label>
        <input type="text" placeholder={t.taskPlaceholder} value={titulo} onChange={(e) => setTitulo(e.target.value)} />
      </div>
      <div className="form-control">
        <label>{t.date}</label>
        <input type="text" placeholder={t.datePlaceholder} value={dia} onChange={(e) => setDia(e.target.value)} />
      </div>
      <div className="form-control-check">
        <input type="checkbox" id="importante" checked={importante} onChange={(e) => setImportante(e.target.checked)} />
        <label htmlFor="importante">{t.important}</label>
      </div>
      <button type="submit" className="btn btn-block success">{t.addTask}</button>
      <Modal isOpen={showModal} onClose={() => setShowModal(false)} title={t.modalTitle} message={t.modalMessage} type="warning" />
    </form>
  );
};

export default AddTask;
