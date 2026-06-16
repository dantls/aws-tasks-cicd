import React, { createContext, useContext, useState } from "react";

const translations = {
  pt: {
    appTitle: "TAREFAS 2026 · Alta Disponibilidade",
    task: "Tarefa",
    taskPlaceholder: "O que você precisa fazer?",
    date: "Data/Prazo",
    datePlaceholder: "Quando?",
    important: "Importante",
    addTask: "Adicionar Tarefa",
    noTasks: "Nenhuma tarefa aqui 📝",
    noTasksHint: "Adicione sua primeira tarefa no formulário acima!",
    showing: "Mostrando",
    of: "de",
    tasks: "tarefas",
    modalTitle: "Campo obrigatório",
    modalMessage: "Por favor, adicione uma descrição para a tarefa",
    footer: "App de Tarefas 2026",
  },
  en: {
    appTitle: "TASKS 2026 · High Availability",
    task: "Task",
    taskPlaceholder: "What do you need to do?",
    date: "Date/Deadline",
    datePlaceholder: "When?",
    important: "Important",
    addTask: "Add New Task",
    noTasks: "No tasks here 📝",
    noTasksHint: "Add your first task using the form above!",
    showing: "Showing",
    of: "of",
    tasks: "tasks",
    modalTitle: "Required field",
    modalMessage: "Please add a description for the task",
    footer: "Tasks App 2026",
  },
};

const I18nContext = createContext();

export const I18nProvider = ({ children }) => {
  const [lang, setLang] = useState("pt");
  const t = translations[lang];
  const toggleLang = () => setLang((l) => (l === "pt" ? "en" : "pt"));
  return (
    <I18nContext.Provider value={{ t, lang, toggleLang }}>
      {children}
    </I18nContext.Provider>
  );
};

export const useI18n = () => useContext(I18nContext);
