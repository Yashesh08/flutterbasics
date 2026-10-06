const express = require('express');
const mongoose = require('mongoose');
const MenuItem = require('../models/MenuItem');
const { authenticateToken, requireAdminOrStaff } = require('../middleware/auth');

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

function formatItem(item) {
  return {
    id: item._id.toString(),
    name: item.name,
    category: item.category,
    price: item.price,
    prepTime: item.prepTime,
    imageUrl: item.imageUrl || '',
    available: item.available ?? true,
    createdAt: item.createdAt?.toISOString(),
    updatedAt: item.updatedAt?.toISOString(),
  };
}

// GET /api/menu - fetch all menu items (auto-seeds if empty)
router.get('/', async (req, res, next) => {
  try {
    let items = await MenuItem.find().sort({ createdAt: -1 });

    if (items.length === 0) {
      items = await MenuItem.insertMany(initialMenuItems);
    }

    return res.json(items.map(formatItem));
  } catch (error) {
    return next(error);
  }
});

// GET /api/menu/:id - fetch single menu item
router.get('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid menu item ID format.' });
    }

    const item = await MenuItem.findById(id);
    if (!item) {
      return res.status(404).json({ message: 'Menu item not found.' });
    }

    return res.json(formatItem(item));
  } catch (error) {
    return next(error);
  }
});

// POST /api/menu - create new menu item (admin/staff only)
router.post('/', authenticateToken, requireAdminOrStaff, async (req, res, next) => {
  try {
    const { name, price, category, prepTime, imageUrl, available } = req.body;

    if (!name || typeof name !== 'string' || !name.trim()) {
      return res.status(400).json({ message: 'Item name is required.' });
    }

    const parsedPrice = parseFloat(price);
    if (isNaN(parsedPrice) || parsedPrice < 0) {
      return res.status(400).json({ message: 'Price must be a non-negative number.' });
    }

    const newItem = await MenuItem.create({
      name: name.trim(),
      price: parsedPrice,
      category: category && typeof category === 'string' ? category.trim() : 'Meals',
      prepTime: prepTime && typeof prepTime === 'string' && prepTime.trim() ? prepTime.trim() : '10 min',
      imageUrl: imageUrl && typeof imageUrl === 'string' ? imageUrl.trim() : '',
      available: available !== undefined ? Boolean(available) : true,
    });

    return res.status(201).json(formatItem(newItem));
  } catch (error) {
    if (error.name === 'ValidationError') {
      return res.status(400).json({ message: error.message });
    }
    return next(error);
  }
});

// PUT /api/menu/:id - update existing menu item (admin/staff only)
router.put('/:id', authenticateToken, requireAdminOrStaff, async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid menu item ID format.' });
    }

    const { name, price, category, prepTime, imageUrl, available } = req.body;
    const updateData = {};

    if (name !== undefined) {
      if (typeof name !== 'string' || !name.trim()) {
        return res.status(400).json({ message: 'Item name cannot be empty.' });
      }
      updateData.name = name.trim();
    }

    if (price !== undefined) {
      const parsedPrice = parseFloat(price);
      if (isNaN(parsedPrice) || parsedPrice < 0) {
        return res.status(400).json({ message: 'Price must be a non-negative number.' });
      }
      updateData.price = parsedPrice;
    }

    if (category !== undefined) {
      updateData.category = category.trim();
    }

    if (prepTime !== undefined) {
      updateData.prepTime = prepTime.trim();
    }

    if (imageUrl !== undefined) {
      updateData.imageUrl = imageUrl.trim();
    }

    if (available !== undefined) {
      updateData.available = Boolean(available);
    }

    const updatedItem = await MenuItem.findByIdAndUpdate(
      id,
      { $set: updateData },
      { new: true, runValidators: true }
    );

    if (!updatedItem) {
      return res.status(404).json({ message: 'Menu item not found.' });
    }

    return res.json(formatItem(updatedItem));
  } catch (error) {
    if (error.name === 'ValidationError') {
      return res.status(400).json({ message: error.message });
    }
    return next(error);
  }
});

// DELETE /api/menu/:id - delete existing menu item (admin/staff only)
router.delete('/:id', authenticateToken, requireAdminOrStaff, async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid menu item ID format.' });
    }

    const deletedItem = await MenuItem.findByIdAndDelete(id);
    if (!deletedItem) {
      return res.status(404).json({ message: 'Menu item not found.' });
    }

    return res.json({
      message: 'Menu item deleted successfully.',
      id: deletedItem._id.toString(),
      item: formatItem(deletedItem),
    });
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
      items: items.map(formatItem),
    });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
