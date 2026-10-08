const express = require('express');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const Order = require('../models/Order');

const router = express.Router();

// Helper to generate sequential order token (e.g. T-101, T-102...)
async function generateOrderToken() {
  const count = await Order.countDocuments({ tokenNumber: { $ne: null } });
  return `T-${101 + count}`;
}

// POST /api/orders - place a new order (online or offline cash payment)
router.post('/', async (req, res, next) => {
  try {
    const {
      userId,
      studentName,
      studentEmail,
      items,
      totalAmount,
      orderType = 'dine-in',
      paymentMethod = 'online',
      specialInstructions = '',
    } = req.body;

    if (!studentName || !studentEmail || !items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({
        message: 'Student name, email, and at least one item are required.',
      });
    }

    const parsedTotal = parseFloat(totalAmount);
    if (isNaN(parsedTotal) || parsedTotal < 0) {
      return res.status(400).json({ message: 'Valid total amount is required.' });
    }

    const bufferMinutes = 3;
    const prepTimes = items.map((i) => {
      const match = String(i.prepTime || '').match(/\d+/);
      return match ? parseInt(match[0], 10) : 8;
    });
    const maxPrepTime = prepTimes.length > 0 ? Math.max(...prepTimes) : 8;

    const isOnline = paymentMethod !== 'offline';
    let tokenNumber = null;
    let status = 'awaiting_payment';
    let paymentStatus = 'pending_payment';
    let ordersAhead = null;
    let queuePosition = null;
    let queueWaitTime = 'Pay cash at counter';
    let estimatedPrepTime = 'Pending token at counter';
    let expectedReadyAt = null;

    if (isOnline) {
      // ── ONLINE PAYMENT ──────────────────────────────────────────────────
      // Token generated automatically and order goes immediately to kitchen
      tokenNumber = await generateOrderToken();
      paymentStatus = 'paid';
      status = 'pending';

      const activeKitchenOrders = await Order.find({
        status: { $in: ['pending', 'preparing'] },
      }).select('status items');

      ordersAhead = activeKitchenOrders.length;
      queuePosition = ordersAhead + 1;
      const queueWaitMinutes = ordersAhead === 0 ? 0 : Math.ceil(ordersAhead / 2) * 3;
      queueWaitTime = `${queueWaitMinutes} min`;

      const totalEtaMinutes = maxPrepTime + queueWaitMinutes + bufferMinutes;
      estimatedPrepTime = `${totalEtaMinutes} min`;
      expectedReadyAt = new Date(Date.now() + totalEtaMinutes * 60 * 1000);
    } else {
      // ── OFFLINE CASH PAYMENT ─────────────────────────────────────────────
      // Student orders, but must collect token from staff at counter after paying cash.
      // Order does NOT go to kitchen until token is issued!
      tokenNumber = null;
      paymentStatus = 'pending_payment';
      status = 'awaiting_payment';
      ordersAhead = null;
      queuePosition = null;
      queueWaitTime = 'Pay cash at counter';
      estimatedPrepTime = 'Pending token at counter';
      expectedReadyAt = null;
    }

    const validOrderType = orderType === 'takeaway' ? 'takeaway' : 'dine-in';

    const formattedItems = items.map((i) => {
      const parsedPrice = parseFloat(i.price) || 0;
      const parsedQty = parseInt(i.quantity, 10) || 1;
      const rawId = i.menuItemId || i.id;
      const validMenuItemId = mongoose.Types.ObjectId.isValid(rawId)
        ? rawId
        : new mongoose.Types.ObjectId();

      return {
        menuItemId: validMenuItemId,
        name: i.name || 'Unnamed item',
        price: parsedPrice,
        quantity: parsedQty,
        subtotal: i.subtotal !== undefined ? parseFloat(i.subtotal) : parsedPrice * parsedQty,
        prepTime: i.prepTime || `${maxPrepTime} min`,
      };
    });

    const orderData = {
      studentName: studentName.trim(),
      studentEmail: studentEmail.trim().toLowerCase(),
      items: formattedItems,
      totalAmount: parsedTotal,
      orderType: validOrderType,
      status,
      paymentMethod: isOnline ? 'online' : 'offline',
      paymentStatus,
      tokenNumber,
      expectedReadyAt,
      estimatedPrepTime,
      queuePosition,
      ordersAhead,
      queueWaitTime,
      specialInstructions: typeof specialInstructions === 'string' ? specialInstructions.trim() : '',
    };

    if (userId && mongoose.Types.ObjectId.isValid(userId)) {
      orderData.userId = userId;
    }

    const order = await Order.create(orderData);

    return res.status(201).json(formatOrder(order));
  } catch (error) {
    if (error.name === 'ValidationError') {
      return res.status(400).json({ message: error.message });
    }
    return next(error);
  }
});

// GET /api/orders - fetch orders (optionally filter by email, status, or orderType)
router.get('/', async (req, res, next) => {
  try {
    const filter = {};
    if (req.query.email) {
      filter.studentEmail = req.query.email.trim().toLowerCase();
    }
    if (req.query.userId && mongoose.Types.ObjectId.isValid(req.query.userId)) {
      filter.userId = req.query.userId;
    }
    if (req.query.status) {
      filter.status = req.query.status;
    }
    if (req.query.orderType) {
      filter.orderType = req.query.orderType;
    }

    const orders = await Order.find(filter).sort({ createdAt: -1 }).limit(100);
    return res.json(orders.map(formatOrder));
  } catch (error) {
    return next(error);
  }
});

// GET /api/orders/queue-estimate - predict ETA using current kitchen queue
router.get('/queue-estimate', async (req, res, next) => {
  try {
    const activeOrders = await Order.find({
      status: { $in: ['pending', 'preparing'] },
    }).select('status items');

    const ordersAhead = activeOrders.length;
    const pendingCount = activeOrders.filter((o) => o.status === 'pending').length;
    const preparingCount = activeOrders.filter((o) => o.status === 'preparing').length;

    // Kitchen throughput: 2 concurrent cooking stations, ~3 min wait per pair of orders
    const queueWaitMinutes = ordersAhead === 0 ? 0 : Math.ceil(ordersAhead / 2) * 3;
    const bufferMinutes = 3;

    let itemPrepMinutes = 8;
    if (req.query.prepTime) {
      const match = String(req.query.prepTime).match(/\d+/);
      if (match) itemPrepMinutes = parseInt(match[0], 10);
    }

    const totalEtaMinutes = itemPrepMinutes + queueWaitMinutes + bufferMinutes;

    return res.json({
      ordersInQueue: ordersAhead,
      ordersAhead,
      queuePosition: ordersAhead + 1,
      pendingCount,
      preparingCount,
      queueWaitMinutes,
      itemPrepMinutes,
      bufferMinutes,
      totalEtaMinutes,
      estimatedPrepTime: `${totalEtaMinutes} min`,
      queueWaitTime: `${queueWaitMinutes} min`,
      kitchenCapacity: 2,
    });
  } catch (error) {
    return next(error);
  }
});

// GET /api/orders/my - fetch student's own past and active orders from MongoDB
router.get('/my', async (req, res, next) => {
  try {
    let email = null;
    let userId = null;

    // Check token in Authorization header
    const authHeader = req.headers['authorization'];
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.slice(7).trim();
      if (token.startsWith('seed-session-')) {
        email = token.includes('staff') ? 'staff@campus.test' : 'student@campus.test';
      } else {
        try {
          const secret = process.env.JWT_SECRET || 'campus-canteen-super-secret-jwt-key-2024';
          const decoded = jwt.verify(token, secret);
          email = decoded.email;
          userId = decoded.sub;
        } catch (_) {
          // Token expired or invalid, will check query/headers
        }
      }
    }

    // Also support query param or dev header
    if (!email && req.query.email) {
      email = req.query.email.trim().toLowerCase();
    }
    if (!email && req.headers['x-user-email']) {
      email = req.headers['x-user-email'].trim().toLowerCase();
    }
    if (!userId && req.query.userId && mongoose.Types.ObjectId.isValid(req.query.userId)) {
      userId = req.query.userId;
    }

    if (!email && !userId) {
      return res.status(400).json({
        message: 'Student authentication token or email query parameter is required to view order history.',
      });
    }

    const filter = {};
    if (userId) {
      filter.$or = [{ userId: userId }, { studentEmail: email }];
    } else {
      filter.studentEmail = email;
    }

    if (req.query.status) {
      filter.status = req.query.status;
    }

    const orders = await Order.find(filter).sort({ createdAt: -1 });
    return res.json(orders.map(formatOrder));
  } catch (error) {
    return next(error);
  }
});

// GET /api/orders/:id - fetch a single order
router.get('/:id', async (req, res, next) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ message: 'Invalid order ID format.' });
    }

    const order = await Order.findById(req.params.id);
    if (!order) {
      return res.status(404).json({ message: 'Order not found.' });
    }
    return res.json(formatOrder(order));
  } catch (error) {
    return next(error);
  }
});

// PATCH /api/orders/:id/issue-token - staff confirms cash payment at counter, issues token, sends order to kitchen
router.patch('/:id/issue-token', async (req, res, next) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ message: 'Invalid order ID format.' });
    }

    const order = await Order.findById(req.params.id);
    if (!order) {
      return res.status(404).json({ message: 'Order not found.' });
    }

    if (order.tokenNumber) {
      return res.status(400).json({
        message: `Token ${order.tokenNumber} has already been issued for this order.`,
        order: formatOrder(order),
      });
    }

    // 1. Generate token
    const tokenNumber = await generateOrderToken();

    // 2. Order enters kitchen queue!
    const activeKitchenOrders = await Order.find({
      status: { $in: ['pending', 'preparing'] },
    }).select('status items');

    const ordersAhead = activeKitchenOrders.length;
    const queuePosition = ordersAhead + 1;
    const queueWaitMinutes = ordersAhead === 0 ? 0 : Math.ceil(ordersAhead / 2) * 3;
    const bufferMinutes = 3;

    const prepTimes = order.items.map((i) => {
      const match = String(i.prepTime || '').match(/\d+/);
      return match ? parseInt(match[0], 10) : 8;
    });
    const maxPrepTime = prepTimes.length > 0 ? Math.max(...prepTimes) : 8;
    const totalEtaMinutes = maxPrepTime + queueWaitMinutes + bufferMinutes;
    const estimatedPrepTime = `${totalEtaMinutes} min`;
    const expectedReadyAt = new Date(Date.now() + totalEtaMinutes * 60 * 1000);

    order.paymentStatus = 'paid';
    order.tokenNumber = tokenNumber;
    order.status = 'pending'; // Now goes to kitchen!
    order.ordersAhead = ordersAhead;
    order.queuePosition = queuePosition;
    order.queueWaitTime = `${queueWaitMinutes} min`;
    order.estimatedPrepTime = estimatedPrepTime;
    order.expectedReadyAt = expectedReadyAt;

    await order.save();
    return res.json(formatOrder(order));
  } catch (error) {
    return next(error);
  }
});

// PATCH /api/orders/:id/status - update order status (admin)
router.patch('/:id/status', async (req, res, next) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ message: 'Invalid order ID format.' });
    }

    const { status } = req.body;
    const validStatuses = [
      'awaiting_payment',
      'pending',
      'preparing',
      'ready',
      'collected',
      'cancelled',
    ];
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
          awaitingPaymentCount: {
            $sum: { $cond: [{ $eq: ['$status', 'awaiting_payment'] }, 1, 0] },
          },
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
        awaitingPaymentCount: 0,
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
    userId: order.userId ? order.userId.toString() : undefined,
    studentName: order.studentName,
    studentEmail: order.studentEmail,
    items: order.items.map((i) => ({
      menuItemId: i.menuItemId?.toString() || '',
      name: i.name,
      price: i.price,
      quantity: i.quantity,
      subtotal: i.subtotal,
      prepTime: i.prepTime || '',
    })),
    totalAmount: order.totalAmount,
    orderType: order.orderType || 'dine-in',
    status: order.status,
    paymentMethod: order.paymentMethod || 'online',
    paymentStatus: order.paymentStatus || 'paid',
    tokenNumber: order.tokenNumber || null,
    specialInstructions: order.specialInstructions,
    estimatedPrepTime: order.estimatedPrepTime,
    queuePosition: order.queuePosition != null ? order.queuePosition : null,
    ordersAhead: order.ordersAhead != null ? order.ordersAhead : null,
    queueWaitTime: order.queueWaitTime || '0 min',
    expectedReadyAt: order.expectedReadyAt ? order.expectedReadyAt.toISOString() : undefined,
    createdAt: order.createdAt ? order.createdAt.toISOString() : undefined,
    updatedAt: order.updatedAt ? order.updatedAt.toISOString() : undefined,
  };
}

module.exports = router;
