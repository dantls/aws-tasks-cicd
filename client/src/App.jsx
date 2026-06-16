import React, { useState, useEffect } from "react";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import { ThemeProvider } from "./contexts/ThemeContext.jsx";
import { LogProvider, useLog } from "./contexts/LogContext.jsx";
import { I18nProvider, useI18n } from "./contexts/I18nContext.jsx";
import Header from "./components/Header.jsx";
import Footer from "./components/Footer.jsx";
import Tasks from "./components/Tasks.jsx";
import AddTask from "./components/AddTask.jsx";
import DebugLogs from "./components/DebugLogs.jsx";

const apiUrl = import.meta.env.VITE_API_URL || "http://localhost:8080";

function AppContent() {
  const [tasks, setTasks] = useState([]);
  const { logApiRequest, logApiResponse, logApiError, addLog } = useLog();
  const { t } = useI18n();

  useEffect(() => {
    addLog('INFO', 'Application started', `API URL configured: ${apiUrl}`);
    getTasks();
  }, []);

  const getTasks = async () => {
    try {
      const tasksFromServer = await fetchTasks();
      setTasks(tasksFromServer);
    } catch (error) {
      addLog('ERROR', 'Failed to load tasks', error.message);
    }
  };

  //Listar Tarefas
  const fetchTasks = async () => {
    const url = `${apiUrl}/api/tarefas`;
    logApiRequest('GET', url);
    
    try {
      const res = await fetch(url);
      const data = await res.json();
      
      logApiResponse('GET', url, res.status, data);
      
      if (!res.ok) {
        throw new Error(`HTTP ${res.status}: ${res.statusText}`);
      }
      
      return data;
    } catch (error) {
      logApiError('GET', url, error);
      throw error;
    }
  };

  //Listar Tarefa
  const fetchTask = async (uuid) => {
    const url = `${apiUrl}/api/tarefas/${uuid}`;
    logApiRequest('GET', url);
    
    try {
      const res = await fetch(url);
      const data = await res.json();
      
      logApiResponse('GET', url, res.status, data);
      
      if (!res.ok) {
        throw new Error(`HTTP ${res.status}: ${res.statusText}`);
      }
      
      return data;
    } catch (error) {
      logApiError('GET', url, error);
      throw error;
    }
  };

  //Alternar Importante
  const toggleReminder = async (uuid) => {
    try {
      const taskToToggle = await fetchTask(uuid);
      const updatedTask = {
        ...taskToToggle,
        importante: !taskToToggle.importante,
      };

      const url = `${apiUrl}/api/tarefas/update_priority/${uuid}`;
      logApiRequest('PUT', url, updatedTask);

      const res = await fetch(url, {
        method: "PUT",
        headers: {
          "Content-type": "application/json",
        },
        body: JSON.stringify(updatedTask),
      });
      
      const data = await res.json();
      
      logApiResponse('PUT', url, res.status, data);
      
      if (!res.ok) {
        throw new Error(`HTTP ${res.status}: ${res.statusText}`);
      }
      
      setTasks(
        tasks.map((task) =>
          task.uuid === uuid ? { ...task, importante: data.importante } : task
        )
      );
      
      addLog('SUCCESS', 'Priority updated', `Task ${uuid} - Important: ${data.importante}`);
    } catch (error) {
      addLog('ERROR', 'Failed to update priority', error.message);
    }
  };

  //Adicionar Tarefa
  const addTask = async (task) => {
    const url = `${apiUrl}/api/tarefas`;
    logApiRequest('POST', url, task);
    
    try {
      const res = await fetch(url, {
        method: "POST",
        headers: {
          "Content-type": "application/json",
        },
        body: JSON.stringify(task),
      });
      
      const data = await res.json();
      
      logApiResponse('POST', url, res.status, data);
      
      if (!res.ok) {
        throw new Error(`HTTP ${res.status}: ${res.statusText}`);
      }
      
      setTasks([...tasks, data]);
      addLog('SUCCESS', 'Task created', `"${task.titulo}" added successfully`);
    } catch (error) {
      logApiError('POST', url, error);
      addLog('ERROR', 'Failed to create task', error.message);
    }
  };

  //Remover tarefa
  const deleteTask = async (uuid) => {
    const url = `${apiUrl}/api/tarefas/${uuid}`;
    logApiRequest('DELETE', url);
    
    try {
      const res = await fetch(url, {
        method: "DELETE",
      });
      
      logApiResponse('DELETE', url, res.status);
      
      if (!res.ok) {
        throw new Error(`HTTP ${res.status}: ${res.statusText}`);
      }
      
      setTasks(tasks.filter((task) => task.uuid !== uuid));
      addLog('SUCCESS', 'Task deleted', `Task ${uuid} removed successfully`);
    } catch (error) {
      logApiError('DELETE', url, error);
      addLog('ERROR', 'Failed to delete task', error.message);
    }
  };

  // Componente para página principal
  const HomePage = () => (
    <>
      <AddTask onAdd={addTask} />
      {tasks.length > 0 ? (
        <Tasks
          tasks={tasks}
          onDelete={deleteTask}
          onToggle={toggleReminder}
        />
      ) : (
        <div className="empty-state">
          <h3>{t.noTasks}</h3>
          <p>{t.noTasksHint}</p>
        </div>
      )}
    </>
  );

  return (
    <div className="app">
      <Router>
        <div className="container">
          <Header />

          <Routes>
            <Route path="/" element={<HomePage />} />
          </Routes>
          <Footer />
        </div>
        <DebugLogs />
      </Router>
    </div>
  );
}

function App() {
  return (
    <I18nProvider>
      <ThemeProvider>
        <LogProvider>
          <AppContent />
        </LogProvider>
      </ThemeProvider>
    </I18nProvider>
  );
}

export default App;
