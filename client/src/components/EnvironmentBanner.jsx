import React, { useState, useEffect } from "react";

const EnvironmentBanner = () => {
  const [label, setLabel] = useState(null);

  const getApiUrl = () => {
    if (import.meta.env.VITE_API_URL) {
      return import.meta.env.VITE_API_URL;
    }

    if (window.location.port === "8080") {
      return window.location.origin;
    }

    return "http://localhost:8080";
  };

  useEffect(() => {
    const fetchAmbiente = async () => {
      try {
        const response = await fetch(`${getApiUrl()}/api/ambiente`);
        if (response.ok) {
          const data = await response.json();
          setLabel(data.label);
        }
      } catch (error) {
        console.warn("Falha ao buscar /api/ambiente:", error.message);
      }
    };

    fetchAmbiente();
  }, []);

  if (!label) {
    return null;
  }

  const isDev = label.toLowerCase().includes("development");

  return (
    <h2 className={`environment-subtitle ${isDev ? "development" : "production"}`}>
      {label}
    </h2>
  );
};

export default EnvironmentBanner;
