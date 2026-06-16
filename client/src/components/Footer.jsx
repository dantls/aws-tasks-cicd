import React from "react";
import { useI18n } from "../contexts/I18nContext.jsx";

const Footer = () => {
  const { t } = useI18n();
  return (
    <footer>
      <div className="footer-content">
        <p>{t.footer}</p>
      </div>
    </footer>
  );
};

export default Footer;
