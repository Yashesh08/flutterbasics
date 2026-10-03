const express = require('express');
const Order = require('../models/Order');

const router = express.Router();

// POST /api/orders - place a new order
router.post('/', async (req, res, next) => {
  try {
    const { studentName, studentEmail, items, totalAmount, specialInstructions } = req.body;

    if (!studentName || !studentEmail || !items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ message: 'Student name, email, and at least one item are required.' });
    }

    // Calculate estimated prep time as the max prep time across items + 3 min buffer
    const estimatedPrepTime = `${Math.max(...items.map((i) => parseInt(i.prepTime || '5', 10))) + 3} min`;

    const order = await Order.create({
      studentName: studentName.trim(),
      studentEmail: studentEmail.trim().toLowerCase(),
      items: items.map((i) => ({
        menuItemId: i.menuItemId || i.id,
        name: i.name,
        price: i.price,
        quantity: i.quantity,
        subtotal: i.price * i.quantity,
      })),
      totalAmount,
      specialInstructions: specialInstructions || '',
      estimatedPrepTime,
    });

    return res.status(201).json(formatOrder(order));
  } catch (error) {
    return next(error);
  }
});

// GET /api/orders - fetch orders (optionally filter by email or status)
router.get('/', async (req, res, next) => {
  try {
    const filter = {};
    if (req.query.email) {
      filter.studentEmail = req.query.email.trim().toLowerCase();
    }
    if (req.query.status) {
      filter.status = req.query.status;
    }

    const orders = await Order.find(filter).sort({ createdAt: -1 }).limit(100);
    return res.json(orders.map(formatOrder));
  } catch (error) {
    return next(error);
  }
});

// GET /api/orders/:id - fetch a single order
router.get('/:id', async (req, res, next) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) {
      return res.status(404).json({ message: 'Order not found.' });
    }
    return res.json(formatOrder(order));
  } catch (error) {
    return next(error);
  }
});

// PATCH /api/orders/:id/status - update order status (admin)
router.patch('/:id/status', async (req, res, next) => {
  try {
    const { status } = req.body;
    const validStatuses = ['pending', 'preparing', 'ready', 'collected', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        message: `Invalid status. Must be one of: ${validStatuses.join(', ')}`,
      });
    }

    const order = await Order.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true, runValidators: true }
    );

    if (!order) {
      return res.status(404).json({ message: 'Order not found.' });
    }

    return res.json(formatOrder(order));
  } catch (error) {
    return next(error);
  }
});

// GET /api/orders/stats/summary - admin dashboard stats
router.get('/stats/summary', async (req, res, next) => {
  try {
    const [stats] = await Order.aggregate([
      {
        $group: {
          _id: null,
          totalOrders: { $sum: 1 },
          totalRevenue: { $sum: '$totalAmount' },
          pendingCount: { $sum: { $cond: [{ $eq: ['$status', 'pending'] }, 1, 0] } },
          preparingCount: { $sum: { $cond: [{ $eq: ['$status', 'preparing'] }, 1, 0] } },
          readyCount: { $sum: { $cond: [{ $eq: ['$status', 'ready'] }, 1, 0] } },
          collectedCount: { $sum: { $cond: [{ $eq: ['$status', 'collected'] }, 1, 0] } },
          cancelledCount: { $sum: { $cond: [{ $eq: ['$status', 'cancelled'] }, 1, 0] } },
        },
      },
    ]);

    return res.json(
      stats || {
        totalOrders: 0,
        totalRevenue: 0,
        pendingCount: 0,
        preparingCount: 0,
        readyCount: 0,
        collectedCount: 0,
        cancelledCount: 0,
      }
    );
  } catch (error) {
    return next(error);
  }
});

function formatOrder(order) {
  return {
    id: order._id.toString(),
    studentName: order.studentName,
    studentEmail: order.studentEmail,
    items: order.items.map((i) => ({
      menuItemId: i.menuItemId?.toString() || '',
      name: i.name,
      price: i.price,
      quantity: i.quantity,
      subtotal: i.subtotal,
    })),
    totalAmount: order.totalAmount,
    status: order.status,
    specialInstructions: order.specialInstructions,
    estimatedPrepTime: order.estimatedPrepTime,
    createdAt: order.createdAt.toISOString(),
    updatedAt: order.updatedAt.toISOString(),
  };
}

module.exports = router;
