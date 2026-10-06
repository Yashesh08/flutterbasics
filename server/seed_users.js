require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./models/User');

async function seedUsers() {
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/canteen';
  await mongoose.connect(uri);
  console.log('Connected to MongoDB');

  const defaultUsers = [
    {
      name: 'Ravi Kumar',
      email: 'staff@campus.test',
      password: 'staff123',
      role: 'staff',
    },
    {
      name: 'Asha Patel',
      email: 'student@campus.test',
      password: 'student123',
      role: 'student',
    },
    {
      name: 'Admin User',
      email: 'admin@campus.test',
      password: 'admin123',
      role: 'staff',
    },
  ];

  for (const u of defaultUsers) {
    const existing = await User.findOne({ email: u.email });
    if (!existing) {
      const hash = await bcrypt.hash(u.password, 12);
      await User.create({
        name: u.name,
        email: u.email,
        password: hash,
        role: u.role,
      });
      console.log(`Created MongoDB user: ${u.email} (${u.role})`);
    } else {
      console.log(`User already exists in MongoDB: ${u.email}`);
    }
  }

  await mongoose.disconnect();
  console.log('User seeding finished.');
}

seedUsers().catch(err => {
  console.error(err);
  process.exit(1);
});
