import React, { useState } from "react";
import "./Main.css";
import { debugData } from "../utils/debugData";
import { fetchNui } from "../utils/fetchNui";

debugData([
  {
    action: "setVisible",
    data: true,
  },
]);

const Hud: React.FC = () => {
  return (
    <div className="nui-wrapper">
    </div>
  );
};

export default Hud;
