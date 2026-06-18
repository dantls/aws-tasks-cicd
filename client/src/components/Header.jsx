import React from "react";
import { FaSun, FaMoon } from "react-icons/fa";
import { useTheme } from "../contexts/ThemeContext.jsx";
import { useI18n } from "../contexts/I18nContext.jsx";
import VersionInfo from "./VersionInfo";
import EnvironmentBanner from "./EnvironmentBanner";

const Header = ({ title }) => {
  const { isDarkMode, toggleTheme } = useTheme();
  const { t, lang, toggleLang } = useI18n();

  return (
    <header className="header">
      <div className="header-title">
        <h1>{title || t.appTitle}</h1>
        <EnvironmentBanner />
      </div>
      <div className="header-controls">
        <VersionInfo />
        <button
          className="lang-toggle"
          onClick={toggleLang}
          title={lang === "pt" ? "Switch to English" : "Mudar para Português"}
        >
          {lang === "pt" ? "🇺🇸 EN" : "🇧🇷 PT"}
        </button>
        <button
          className="theme-toggle"
          onClick={toggleTheme}
          title={isDarkMode ? "Tema claro" : "Tema escuro"}
        >
          {isDarkMode ? <FaSun /> : <FaMoon />}
        </button>
      </div>
    </header>
  );
};

export default Header;
