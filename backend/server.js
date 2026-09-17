require("dotenv").config();

const express = require("express");
const cors = require("cors");
const mongoose = require("mongoose");

const MenuItem = require("./models/menuItem");

const app = express();

app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 5000;

// Connect to MongoDB
mongoose
  .connect(process.env.MONGO_URI)
  .then(() => {
    console.log("MongoDB connected");
  })
  .catch((error) => {
    console.error("MongoDB connection failed:", error.message);
  });

// GET all menu items
app.get("/api/menu", async (req, res) => {
  try {
    const menuItems = await MenuItem.find();
    res.json(menuItems);
  } catch (error) {
    res.status(500).json({
      message: "Failed to fetch menu",
    });
  }
});

// Test route
app.get("/", (req, res) => {
  res.send("Canteen API is running");
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
