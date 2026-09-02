const mongoose = require('mongoose');

async function connectDatabase() {
  const connectionString = process.env.MONGODB_URI;
  if (!connectionString) {
    throw new Error('MONGODB_URI is required. Copy .env.example to .env and configure it.');
  }

  await mongoose.connect(connectionString);
  console.log('Connected to MongoDB');
}

module.exports = { connectDatabase };
