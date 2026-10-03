const express = require('express');
const MenuItem = require('../models/MenuItem');

const router = express.Router();

const initialMenuItems = [
  {
    name: 'Veggie Wrap',
    category: 'Meals',
    price: 4.50,
    prepTime: '8 min',
    imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400',
    available: true,
  },
  {
    name: 'Chicken Rice Bowl',
    category: 'Meals',
    price: 6.75,
    prepTime: '12 min',
    imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
    available: true,
  },
  {
    name: 'Paneer Sandwich',
    category: 'Snacks',
    price: 3.80,
    prepTime: '6 min',
    imageUrl: 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400',
    available: true,
  },
  {
    name: 'Crispy Samosa',
    category: 'Snacks',
    price: 1.25,
    prepTime: '4 min',
    imageUrl: 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400',
    available: true,
  },
  {
    name: 'Cold Coffee',
    category: 'Drinks',
    price: 2.50,
    prepTime: '3 min',
    imageUrl: 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=400',
    available: true,
  },
  {
    name: 'Fresh Lemonade',
    category: 'Drinks',
    price: 1.80,
    prepTime: '2 min',
    imageUrl: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=400',
    available: true,
  },
  {
    name: 'Chocolate Brownie',
    category: 'Desserts',
    price: 3.00,
    prepTime: '5 min',
    imageUrl: 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=400',
    available: true,
  },
];

// GET /api/menu - fetch all menu items (auto-seeds if empty)
router.get('/', async (req, res, next) => {
  try {
    let items = await MenuItem.find().sort({ createdAt: -1 });

    if (items.length === 0) {
      items = await MenuItem.insertMany(initialMenuItems);
    }

    const formattedItems = items.map((item) => ({
      id: item._id.toString(),
      name: item.name,
      category: item.category,
      price: item.price,
      prepTime: item.prepTime,
      imageUrl: item.imageUrl,
      available: item.available,
    }));

    return res.json(formattedItems);
  } catch (error) {
    return next(error);
  }
});

// POST /api/menu/seed - manually re-seed database with default menu items
router.post('/seed', async (req, res, next) => {
  try {
    await MenuItem.deleteMany({});
    const items = await MenuItem.insertMany(initialMenuItems);
    return res.status(201).json({
      message: 'Database seeded successfully with menu items.',
      count: items.length,
    });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
