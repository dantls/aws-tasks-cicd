import React, { useState, useEffect } from "react";

const EnvironmentBanner = () => {
  const [label, setLabel] = useState(null);

  useEffect(() => {
    const fetchAmbiente = async () => {
      try {
        // Sempre relativo à própria origem: o mesmo container que serve o
        // front-end também serve /api/ambiente, e cada ambiente (prod/dev)
        // tem seu próprio container atrás do ALB. Usar VITE_API_URL aqui
        // furaria o isolamento, pois ele é fixado no build da imagem.
        const response = await fetch("/api/ambiente");
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
