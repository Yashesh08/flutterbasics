const mongoose = require('mongoose');

async function connectDatabase() {
  const connectionString = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/canteen';

  await mongoose.connect(connectionString);
  console.log('Connected to MongoDB');
}

module.exports = { connectDatabase };
