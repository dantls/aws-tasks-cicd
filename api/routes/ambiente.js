module.exports = (app) => {
  const controller = require("../controllers/ambiente")();

  app.route("/api/ambiente").get(controller.get);
};
