module.exports = () => {
  const controller = {};

  controller.get = async (req, res) => {
    res.json({
      label: process.env.ENVIRONMENT_LABEL || "Production Environment",
    });
  };

  return controller;
};
